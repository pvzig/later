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
    var keychain: Keychain {
        var keychain = Keychain(service: "Later: Read Later Extensions", accessGroup: "U63DWZL52M.com.launchsoft.later")
        if #available(OSXApplicationExtension 10.15, *) {
            keychain = keychain.attributes([String(kSecUseDataProtectionKeychain): true])
        }
        return keychain
    }
    
    private let client = IKEngine()
    private let defaults = UserDefaults(suiteName: "U63DWZL52M.com.launchsoft.later")!

    private var instapaperLoginSuccess: (() -> Void)?
    private var instapaperLoginFailure: ((String) -> Void)?

    override public init() {
        super.init()
        client.delegate = self
        IKEngine.setOAuthConsumerKey(Constants.Instapaper.apiKey, andConsumerSecret: Constants.Instapaper.apiSecret)
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
            URLQueryItem(name: "auth_token", value: token)
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
        PocketAPI.shared().consumerKey = Constants.Pocket.consumerKey
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
            pinboardLogin(user: username, token: password, success: success, failure: failure)
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

    func pinboardLogin(user: String,
                       token: String,
                       success: @escaping () -> Void,
                       failure: @escaping (String) -> Void) {

        var components = URLComponents(string: "https://api.pinboard.in/v1/user/api_token")
        components?.queryItems = [
            URLQueryItem(name: "auth_token", value: "\(user):\(token)")
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
                self.keychain[Constants.Pinboard.apiToken] = "\(user):\(token)"
                success()
            }
        }.resume()
    }
    
    func pocketLogin(complete: @escaping (Bool) -> Void) {
        PocketAPI.shared().consumerKey = Constants.Pocket.consumerKey
        PocketAPI.shared().login(handler: { (API: PocketAPI?, error: Error?) -> Void in
            if let error = error {
                if #available(OSX 10.14, *) {
                    os_log(.error, "ReadLaterService failed to save article with error: %@", error.localizedDescription)
                }
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
    
    private var isMigrated: Bool {
        return defaults.bool(forKey: Constants.migrationKey)
    }
    
    func migrate() {
        if let account = defaults.string(forKey: "pinboardAccountName"), let token = keychain[Constants.Pinboard.apiToken], !isMigrated {
            keychain[Constants.Pinboard.apiToken] = "\(account):\(token)"
            defaults.removeObject(forKey: "pinboardAccountName")
            defaults.set(true, forKey: Constants.migrationKey)
        }
    }
}
