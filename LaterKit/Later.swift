//
//  Later.swift
//  LaterKit
//
//  Created by Peter Zignego on 11/17/17.
//  Copyright © 2017 Launch Software. All rights reserved.
//

public enum AccountType {
    case instapaper
    case pocket
    case pinboard

    var accountKey: String {
        switch self {
        case .instapaper:
            return "instapaper"
        case .pinboard:
            return "pinboard"
        case .pocket:
            return "pocket"
        }
    }

    var nameKey: String {
        switch self {
        case .instapaper:
            return "instapaperAccountName"
        case .pinboard:
            return "pinboardAccountName"
        case .pocket:
            return "pocketAccountName"
        }
    }
}

public class Later: NSObject, IKEngineDelegate {

    private struct Constants {
        static let instapaperAPIKey = "3b21ad9ab01a4f85a557a36f59e70bf4"
        static let instapaperAPISecret = "421d798d435c46b897f38c75cefce117"
        static let instapaperTokenKey = "later-instapaper-oauth-token"
        static let instapaperSecretKey = "later-instapaper-secret-token"
    }

    public static let shared = Later()
    private let client = IKEngine()

    private var instapaperLoginSuccess: (() -> Void)?
    private var instapaperLoginFailure: ((String) -> Void)?

    public let saveGroup = DispatchGroup()

    override public init() {
        super.init()
        client.delegate = self
        IKEngine.setOAuthConsumerKey(Constants.instapaperAPIKey, andConsumerSecret: Constants.instapaperAPISecret)
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
        if let account = User.accountName(.instapaper) {
            client.oAuthToken = Keychain.fetchItem(Constants.instapaperTokenKey, account: account)
            client.oAuthTokenSecret = Keychain.fetchItem(Constants.instapaperSecretKey, account: account)
            client.addBookmark(with: url, userInfo: nil)
            saveGroup.leave()
        }
    }

    func addToPinboard(_ url: URL, title: String?) {
        guard
            let user = User.accountName(.pinboard),
            let token = Keychain.fetchItem("later-pinboard-api-token", account: user)
        else {
            saveGroup.leave()
            return
        }
        var components = URLComponents(string: "https://api.pinboard.in/v1/posts/add")
        components?.queryItems = [
            URLQueryItem(name: "url", value: url.absoluteString),
            URLQueryItem(name: "description", value: title ?? url.absoluteString),
            URLQueryItem(name: "auth_token", value: "\(user):\(token)")
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
        PocketAPI.shared().consumerKey = "47240-996424446c9727c03cfc1504"
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
            return
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
                User.setAccount(.pinboard)
                User.setAccountName(.pinboard, account: user)
                Keychain.saveItem(token, account: user, service: "later-pinboard-api-token")
                success()
            }
        }.resume()
    }

    func instapaperLogin(user: String, password: String) {
        _ = client.authToken(forUsername: user, password: password, userInfo: nil)
        User.setAccountName(.instapaper, account: user)
    }

    //MARK: - IKEngineDelegate

    public func engine(_ engine: IKEngine!,
                       connection: IKURLConnection!,
                       didReceiveAuthToken token: String!,
                       andTokenSecret secret: String!) {

        engine.oAuthToken  = token
        engine.oAuthTokenSecret = secret
        if let account = User.accountName(.instapaper) {
            Keychain.saveItem(token, account: account, service: "later-instapaper-oauth-token")
            Keychain.saveItem(secret, account: account, service: "later-instapaper-secret-token")
            User.setAccount(.instapaper)
            instapaperLoginSuccess?()
        } else {
            instapaperLoginFailure?("Failed to save Instapaper token to the keychain.")
        }
    }
}

// MARK: - Remove credentials

extension Later {

    public func delete(type: AccountType) {
        switch type {
        case .instapaper:
            if let account = User.accountName(.instapaper) {
                Keychain.removeItem("later-instapaper-oauth-token", account: account)
                Keychain.removeItem("later-instapaper-secret-token", account: account)
            }
            User.removeService(.instapaper)
        case .pocket:
            User.removeService(.pocket)
        case .pinboard:
            if let account = User.accountName(.pinboard) {
                Keychain.removeItem("later-pinboard-api-token", account: account)
            }
            User.removeService(.pinboard)
        }
    }
}
