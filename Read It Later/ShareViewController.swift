//
//  ShareViewController.swift
//  Read It Later
//
//  Created by Peter Zignego on 11/14/15.
//  Copyright © 2016 Launch Software. All rights reserved.
//

import Cocoa

class ShareViewController: NSViewController, IKEngineDelegate {

    var client: IKEngine? = nil
    var instapaperComplete: Bool = false
    var pinboardComplete: Bool = false
    var pocketComplete: Bool = false
    
    override var nibName: NSNib.Name? {
        return NSNib.Name(rawValue: "ShareViewController")
    }
    
    override func loadView() {
        super.loadView()
        guard
            let item = self.extensionContext?.inputItems[0] as? NSExtensionItem,
            let attachments = item.attachments as? [NSItemProvider]
        else {
            complete()
            return
        }
        for provider in attachments {
            if provider.hasItemConformingToTypeIdentifier(kUTTypePropertyList as String) {
                provider.loadItem(forTypeIdentifier: kUTTypePropertyList as String, options: nil, completionHandler: { (item, error) in
                    let dict = item as? [String: Any]
                    let info = dict?[NSExtensionJavaScriptPreprocessingResultsKey] as? [String: Any]
                    let title = info?["title"] as? String
                    guard let urlString = info?["URL"] as? String, let url = URL(string: urlString) else {
                        self.complete()
                        return
                    }
                    self.saveURL(url, title: title)
                })
            }
        }
    }
    
    func saveURL(_ url: URL, title: String?) {
        if (User.instapaperAccount == true) {
            addToInstapaper(url)
        }
        if (User.pinboardAccount == true) {
            addToPinboard(url, title: title)
        }
        if (User.pocketAccount == true) {
            addToPocket(url)
        }
        completionHandler()
    }
    
    func addToInstapaper(_ url: URL) {
        IKEngine.setOAuthConsumerKey("3b21ad9ab01a4f85a557a36f59e70bf4", andConsumerSecret: "421d798d435c46b897f38c75cefce117")
        client = IKEngine(delegate: self)
        if let account = User.instapaperAccountName {
            client?.oAuthToken = Keychain.fetchItem("later-instapaper-oauth-token", account: account)
            client?.oAuthTokenSecret = Keychain.fetchItem("later-instapaper-secret-token", account: account)
            _ = client?.addBookmark(with: url, userInfo: nil)
        } else {
            completionHandler()
        }
    }
    
    func addToPinboard(_ url: URL, title: String?) {
        guard
            let user = User.pinboardAccountName,
            let token = Keychain.fetchItem("later-pinboard-api-token", account: user)
        else {
            self.pinboardComplete = true
            self.completionHandler()
            return
        }
        var components = URLComponents(string: "https://api.pinboard.in/v1/posts/add")
        components?.queryItems = [
            URLQueryItem(name: "url", value: url.absoluteString),
            URLQueryItem(name: "description", value: title ?? url.absoluteString),
            URLQueryItem(name: "auth_token", value: "\(user):\(token)")
        ]
        guard let url = components?.url else {
            self.pinboardComplete = true
            self.completionHandler()
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            self.pinboardComplete = true
            self.completionHandler()
        }.resume()
    }
    
    func addToPocket(_ url: URL) {
        PocketAPI.shared().consumerKey = "47240-996424446c9727c03cfc1504"
        PocketAPI.shared().save(url, handler:{(API: PocketAPI?, url: URL?, error: Error?) -> Void in
            if (error != nil) {
                self.pocketComplete = true
                self.completionHandler()
            } else {
                self.pocketComplete = true
                self.completionHandler()
            }
        })
    }
    
    //MARK: IKEngineDelegate
    func engine(_ engine: IKEngine!, connection: IKURLConnection!, didAdd bookmark: IKBookmark!) {
        instapaperComplete = true
        completionHandler()
    }
    
    func engine(_ engine: IKEngine!, didFail connection: IKURLConnection!, error: Error!) {
        instapaperComplete = true
        completionHandler()
    }
    
    func completionHandler() {
        var successCount = 0
        var successes = 0
        let accounts = [User.instapaperAccount, User.pinboardAccount, User.pocketAccount]
        accounts.forEach {
            if $0 == true {
                successCount += 1
            }
        }

        let completes = [instapaperComplete, pinboardComplete, pocketComplete]
        completes.forEach {
            if $0 == true {
                successes += 1
            }
        }
        
        if (successes == successCount) {
            complete()
        }
    }
    
    func complete() {
        self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }
    
    deinit {
        complete()
    }
}
