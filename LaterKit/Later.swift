//
//  Later.swift
//  LaterKit
//
//  Created by Peter Zignego on 11/17/17.
//  Copyright © 2017 Launch Software. All rights reserved.
//

import KeychainAccess
import OSLog

public class Later: NSObject, IKEngineDelegate {

    struct Constants {
        struct Instapaper {
            static let apiKey = "3b21ad9ab01a4f85a557a36f59e70bf4"
            static let apiSecret = "421d798d435c46b897f38c75cefce117"
            static let oauthToken = "later-instapaper-oauth-token"
            static let oauthSecret = "later-instapaper-secret-token"
        }
        
        struct Pinboard {
            static let apiToken = "later-pinboard-api-token"
        }
        
        struct Pocket {
            static let consumerKey = "47240-996424446c9727c03cfc1504"
            static let tokenKey = "later-pocket-token"
            static let tokenDigestKey = "later-pocket-token-digest"
        }
        
        static let migrationKey = "version_1_2_0_migrated"
    }

    public static let shared = Later()
    public let saveGroup = DispatchGroup()

    let keychain: Keychain = Keychain(service: "Later: Read Later Extensions", accessGroup: "U63DWZL52M.com.launchsoft.later")
        .attributes([String(kSecUseDataProtectionKeychain): true])
    
    private let client = IKEngine()
    private let defaults = UserDefaults(suiteName: "U63DWZL52M.com.launchsoft.later")!

    private var instapaperLoginSuccess: (() -> Void)?
    private var instapaperLoginFailure: ((String) -> Void)?

    override public init() {
        super.init()
        client.delegate = self
        IKEngine.setOAuthConsumerKey(Constants.Instapaper.apiKey, andConsumerSecret: Constants.Instapaper.apiSecret)
        DispatchQueue.main.async {
            PocketAPI.shared().consumerKey = Constants.Pocket.consumerKey
        }
    }

    public func saveURL(_ url: URL, title: String?) {
        if User.hasAccount(.instapaper) {
            saveGroup.enter()
            addToInstapaper(url)
        }

        if User.hasAccount(.pinboard) {
            saveGroup.enter()
            addToPinboard(url, title: title)
        }

        if User.hasAccount(.pocket) {
            saveGroup.enter()
            addToPocket(url)
        }
    }

    func addToInstapaper(_ url: URL) {
        client.oAuthToken = keychain[Constants.Instapaper.oauthToken]
        client.oAuthTokenSecret = keychain[Constants.Instapaper.oauthSecret]
        client.addBookmark(with: url, userInfo: nil)
    }

    func addToPinboard(_ url: URL, title: String?) {
        guard let token = keychain[Constants.Pinboard.apiToken] else {
            saveGroup.leave()
            return
        }
        // Construct Pinboard save url
        var components = URLComponents(string: "https://api.pinboard.in/v1/posts/add")
        components?.queryItems = [
            URLQueryItem(name: "url", value: url.absoluteString),
            URLQueryItem(name: "description", value: title ?? url.absoluteString),
            URLQueryItem(name: "auth_token", value: token),
            URLQueryItem(name: "toread", value: "yes")
        ]
        guard let url = components?.url else {
            saveGroup.leave()
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        URLSession.shared.dataTask(with: request) { data, response, error in
            self.saveGroup.leave()
        }.resume()
    }

    func addToPocket(_ url: URL) {
        PocketAPI.shared().save(url, handler:{ (API: PocketAPI?, url: URL?, error: Error?) -> Void in
            self.saveGroup.leave()
        })
    }

    // MARK: - IKEngineDelegate
    
    public func engine(_ engine: IKEngine!, connection: IKURLConnection!, didAdd bookmark: IKBookmark!) {
        saveGroup.leave()
    }

    public func engine(_ engine: IKEngine!, didFail connection: IKURLConnection!, error: Error!) {
        // Save artcile failure
        if User.hasAccount(.instapaper) {
            saveGroup.leave()
        // Login attempt
        } else {
            instapaperLoginFailure?("Instapaper login failed.")
        }
    }
}

// MARK: - Login

extension Later {
    public func login(type: AccountType, 
                      username: String,
                      password: String,
                      success: @escaping () -> Void,
                      failure: @escaping (String) -> Void) {

        switch type {
        case .instapaper:
            instapaperLogin(user: username, password: password)
            instapaperLoginSuccess = {
                success()
            }
            instapaperLoginFailure = { error in
                failure(error)
            }
        case .pinboard:
            pinboardLogin(token: password, success: success, failure: failure)
        case .pocket:
            pocketLogin { isLoggedIn in
                if isLoggedIn {
                    success()
                } else {
                    failure("Pocket login failed")
                }
            }
        }
    }

    func pinboardLogin(token: String,
                       success: @escaping () -> Void,
                       failure: @escaping (String) -> Void) {

        var components = URLComponents(string: "https://api.pinboard.in/v1/user/api_token")
        components?.queryItems = [
            URLQueryItem(name: "auth_token", value: token)
        ]
        guard let url = components?.url else {
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                guard let r = response as? HTTPURLResponse, r.statusCode == 200 else {
                    failure("Pinboard API token validation failed.")
                    return
                }
                self.keychain[Constants.Pinboard.apiToken] = token
                success()
            }
        }.resume()
    }
    
    func pocketLogin(complete: @escaping (Bool) -> Void) {
        PocketAPI.shared().login(handler: { (API: PocketAPI?, error: Error?) -> Void in
            if let error = error {
                os_log(.error, "ReadLaterService failed to save article with error: %@", error.localizedDescription)
                complete(false)
            } else {
                complete(true)
            }
        })
    }

    func instapaperLogin(user: String, password: String) {
        _ = client.authToken(forUsername: user, password: password, userInfo: nil)
    }

    //MARK: - IKEngineDelegate

    public func engine(_ engine: IKEngine!, connection: IKURLConnection!, didReceiveAuthToken token: String!, andTokenSecret secret: String!) {
        engine.oAuthToken = token
        engine.oAuthTokenSecret = secret
        keychain[Constants.Instapaper.oauthToken] = token
        keychain[Constants.Instapaper.oauthSecret] = secret
        instapaperLoginSuccess?()
    }
}

// MARK: - Remove credentials

extension Later {

    public func reset() {
        delete(type: .instapaper)
        delete(type: .pinboard)
        delete(type: .pocket)
        if let bundle = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundle)
        }
    }
    
    public func delete(type: AccountType) {
        switch type {
        case .instapaper:
            try? keychain.remove(Constants.Instapaper.oauthToken)
            try? keychain.remove(Constants.Instapaper.oauthSecret)
        case .pocket:
            User.pocketLogout()
        case .pinboard:
            try? keychain.remove(Constants.Pinboard.apiToken)
        }
    }
}

// MARK: - Migration

extension Later {
    
    public func migrate() {
        guard !isMigrated else { return }
        // Instapaper
        if
            let account = defaults.string(forKey: "instapaperAccountName"),
            let token = LegacyKeychain.fetchItem(Constants.Instapaper.oauthToken, account: account),
            let secret = LegacyKeychain.fetchItem(Constants.Instapaper.oauthSecret, account: account) {
            // Set
            keychain[Constants.Instapaper.oauthToken] = token
            keychain[Constants.Instapaper.oauthSecret] = secret
            // Remove
            LegacyKeychain.removeItem(Constants.Instapaper.oauthToken, account: account)
            LegacyKeychain.removeItem(Constants.Instapaper.oauthSecret, account: account)
            defaults.removeObject(forKey: "instapaperAccountName")
        }
        
        // Pinboard
        if
            let account = defaults.string(forKey: "pinboardAccountName"),
            let token = LegacyKeychain.fetchItem(Constants.Pinboard.apiToken, account: account) {
            // Set
            keychain[Constants.Pinboard.apiToken] = "\(account):\(token)"
            // Remove
            LegacyKeychain.removeItem(Constants.Pinboard.apiToken, account: account)
            defaults.removeObject(forKey: "pinboardAccountName")
        }
        
        // Pocket
        if
            let account = defaults.string(forKey: "pocketAccountName"),
            let token = LegacyKeychain.fetchItem(Constants.Pocket.tokenKey, account: account),
            let digest = LegacyKeychain.fetchItem(Constants.Pocket.tokenDigestKey, account: account) {
            // Set
            keychain[Constants.Pocket.tokenKey] = token
            keychain[Constants.Pocket.tokenDigestKey] = digest
            // Remove
            LegacyKeychain.removeItem(Constants.Pocket.tokenKey, account: account)
            LegacyKeychain.removeItem(Constants.Pocket.tokenDigestKey, account: account)
        }
        
        // Migration completed
        defaults.set(true, forKey: Constants.migrationKey)
    }
    
    private var isMigrated: Bool {
        return defaults.bool(forKey: Constants.migrationKey)
    }
}
