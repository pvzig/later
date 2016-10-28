//
//  ShareViewController.swift
//  Read It Later
//
//  Created by Peter Zignego on 11/14/15.
//  Copyright © 2016 Launch Software. All rights reserved.
//

import Cocoa
import Alamofire

class ShareViewController: NSViewController, IKEngineDelegate {

    var client: IKEngine? = nil
    var instapaperComplete: Bool = false
    var pocketComplete: Bool = false
    
    override var nibName: String? {
        return "ShareViewController"
    }
    
    override func loadView() {
        super.loadView()
        guard let item = self.extensionContext?.inputItems[0] as? NSExtensionItem else {
            complete()
            return
        }
        if let provider = item.attachments?.first as? NSItemProvider {
            if (provider.hasItemConformingToTypeIdentifier(kUTTypeURL as String)) {
                provider.loadItem(forTypeIdentifier: kUTTypeURL as String, options: nil, completionHandler: {(result, error) -> Void in
                    if let resultURL = result as? URL {
                        self.saveURL(resultURL)
                        return
                    }
                    self.complete()
                })
            } else {
                complete()
            }
        }
    }
    
    func saveURL(_ url: URL) {
        if (User.instapaperAccount == true) {
            addToInstapaper(url)
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
        let accounts = [User.instapaperAccount, User.pocketAccount]
        accounts.forEach {
            if $0 == true {
                successCount += 1
            }
        }

        let completes = [instapaperComplete, pocketComplete]
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
