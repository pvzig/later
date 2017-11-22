//
//  Later.swift
//  LaterKit
//
//  Created by Peter Zignego on 11/17/17.
//  Copyright © 2017 Launch Software. All rights reserved.
//

import Foundation

public enum AccountType {
    case instapaper
    case pocket
    case pinboard
}

// MARK: Save
public class Later: NSObject, IKEngineDelegate {

    public static let shared = Later()
    private let client = IKEngine()

    private var instapaperLoginSuccess: (() -> Void)?
    private var instapaperLoginFailure: ((String) -> Void)?

    public let saveGroup = DispatchGroup()

    override public init() {
        super.init()
        client.delegate = self
    }

    public func saveURL(_ url: URL, title: String?) {
        if User.instapaperAccount {
            saveGroup.enter()
            addToInstapaper(url)
        }

        if User.pinboardAccount {
            saveGroup.enter()
            addToPinboard(url, title: title)
        }

        if User.pocketAccount {
            saveGroup.enter()
            addToPocket(url)
        }
    }

    func addToInstapaper(_ url: URL) {
        IKEngine.setOAuthConsumerKey("3b21ad9ab01a4f85a557a36f59e70bf4", andConsumerSecret: "421d798d435c46b897f38c75cefce117")
        if let account = User.instapaperAccountName {
            client.oAuthToken = Keychain.fetchItem("later-instapaper-oauth-token", account: account)
            client.oAuthTokenSecret = Keychain.fetchItem("later-instapaper-secret-token", account: account)
            _ = client.addBookmark(with: url, userInfo: nil)
        } else {
            saveGroup.leave()
        }
    }

    func addToPinboard(_ url: URL, title: String?) {
        guard
            let user = User.pinboardAccountName,
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
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            self.saveGroup.leave()
        }.resume()
    }

    func addToPocket(_ url: URL) {
        PocketAPI.shared().consumerKey = "47240-996424446c9727c03cfc1504"
        PocketAPI.shared().save(url, handler:{(API: PocketAPI?, url: URL?, error: Error?) -> Void in
            self.saveGroup.leave()
        })
    }

    //MARK: IKEngineDelegate
    public func engine(_ engine: IKEngine!, connection: IKURLConnection!, didAdd bookmark: IKBookmark!) {
        saveGroup.leave()
    }

    public func engine(_ engine: IKEngine!, didFail connection: IKURLConnection!, error: Error!) {
        // Save artcile failure
        if User.instapaperAccount {
            saveGroup.leave()
        // Login attempt
        } else {
            instapaperLoginFailure?("Instapaper login failed.")
        }
    }
}

//MARK: Login
extension Later {
    // MARK: - Login
    public func login(type: AccountType, username: String, password: String, success: @escaping () -> Void, failure: @escaping (String) -> Void) {
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
            break
        }
    }

    func pinboardLogin(user: String, token: String, success: @escaping () -> Void, failure: @escaping (String) -> Void) {
        var components = URLComponents(string: "https://api.pinboard.in/v1/user/api_token")
        components?.queryItems = [
            URLQueryItem(name: "auth_token", value: "\(user):\(token)")
        ]
        guard let url = components?.url else {
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            DispatchQueue.main.async {
                guard let r = response as? HTTPURLResponse, r.statusCode == 200 else {
                    failure("Pinboard API token validation failed.")
                    return
                }
                User.defaults.set(user, forKey: "pinboardAccountName")
                User.defaults.set(true, forKey: "pinboard")
                Keychain.saveItem(token, account: user, service: "later-pinboard-api-token")
                User.save()
                success()
            }
        }.resume()
    }

    func instapaperLogin(user: String, password: String) {
        IKEngine.setOAuthConsumerKey("3b21ad9ab01a4f85a557a36f59e70bf4",
                                     andConsumerSecret: "421d798d435c46b897f38c75cefce117")
        _ = client.authToken(forUsername: user, password: password, userInfo: nil)
        User.defaults.set(user, forKey: "instapaperAccountName")
        User.save()
    }

    //MARK: IKEngineDelegate
    public func engine(_ engine: IKEngine!, connection: IKURLConnection!, didReceiveAuthToken token: String!, andTokenSecret secret: String!) {
        engine.oAuthToken  = token
        engine.oAuthTokenSecret = secret
        if let account = User.instapaperAccountName {
            Keychain.saveItem(token, account: account, service: "later-instapaper-oauth-token")
            Keychain.saveItem(secret, account: account, service: "later-instapaper-secret-token")
            User.defaults.set(true, forKey: "instapaper")
            User.save()
        }
        instapaperLoginSuccess?()
    }
}

// Remove credentials
extension Later {

    public func delete(type: AccountType) {
        switch type {
        case .instapaper:
            if let account = User.instapaperAccountName {
                Keychain.removeItem("later-instapaper-oauth-token", account: account)
                Keychain.removeItem("later-instapaper-secret-token", account: account)
            }
            User.defaults.set(false, forKey: "instapaper")
            User.defaults.set(nil, forKey: "instapaperAccountName")
            User.save()
        case .pocket:
            User.defaults.set(false, forKey: "pocket")
            User.save()
        case .pinboard:
            if let account = User.pinboardAccountName {
                Keychain.removeItem("later-pinboard-api-token", account: account)
            }
            User.defaults.set(false, forKey: "pinboard")
            User.defaults.set(nil, forKey: "pinboardAccountName")
            User.save()
        }
    }
}
