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

    var client: IKEngine?
    var instapaperComplete: Bool?
    var readabilityComplete: Bool?
    var pocketComplete: Bool?
    
    override func loadView() {
        super.loadView()
        let item = self.extensionContext!.inputItems[0] as! NSExtensionItem
        if let provider = item.attachments?.first as? NSItemProvider {
            if (provider.hasItemConformingToTypeIdentifier(kUTTypeURL as String)) {
                provider.loadItemForTypeIdentifier(kUTTypeURL as String, options: nil, completionHandler: {(result, error) -> Void in
                    if let resultURL = result as? NSURL {
                        self.saveURL(resultURL)
                    }
                })
            }
        }
    }
    
    func saveURL(url: NSURL) {
        if (User.instapaperAccount == true) {
            addToInstapaper(url)
        }
        if (User.readabilityAccount == true) {
            addToReadability(url)
        }
        if (User.pocketAccount == true) {
            addToPocket(url)
        }
        if User.instapaperAccount == false &&
            User.readabilityAccount == false &&
            User.pocketAccount == false {
                completionHandler()
        }
    }
    
    func addToInstapaper(url: NSURL) {
        IKEngine.setOAuthConsumerKey("3b21ad9ab01a4f85a557a36f59e70bf4", andConsumerSecret: "421d798d435c46b897f38c75cefce117")
        client = IKEngine(delegate: self)
        if let account = User.instapaperAccountName {
            client?.OAuthToken = Keychain.fetchItem("later-instapaper-oauth-token", account: account)
            client?.OAuthTokenSecret = Keychain.fetchItem("later-instapaper-secret-token", account: account)
            client?.addBookmarkWithURL(url, userInfo: nil)
            self.completionHandler()
        } else {
            completionHandler()
        }
    }
    
    func addToReadability(url: NSURL) {
        let endpoint = "https://www.readability.com/api/rest/v1/bookmarks/"
        let header = ["Authorization" : OAuth.authorizationHeaderForMethod("POST", url: NSURL(string: endpoint)!, parameters: ["url":url], isMediaUpload: false)]
        Alamofire.request(.POST, endpoint, parameters: ["url":url], encoding: .URL, headers: header).response
        { response in
            self.readabilityComplete = true
            self.completionHandler()
        }
    }
    
    func addToPocket(url: NSURL) {
        PocketAPI.sharedAPI().consumerKey = "47240-996424446c9727c03cfc1504"
        PocketAPI.sharedAPI().saveURL(url, handler:{(API: PocketAPI!, url: NSURL!, error: NSError!) -> Void in
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
    func engine(engine: IKEngine!, connection: IKURLConnection!, didAddBookmark bookmark: IKBookmark!) {
        instapaperComplete = true
        completionHandler()
    }
    
    func engine(engine: IKEngine!, didFailConnection connection: IKURLConnection!, error: NSError!) {
        instapaperComplete = true
        completionHandler()
    }
    
    func completionHandler() {
        var successCount = 0
        if (User.instapaperAccount == true) {
            successCount += 1
        }
        if (User.readabilityAccount == true) {
            successCount += 1
        }
        if (User.pocketAccount == true) {
            successCount += 1
        }
        var successes = 0
        if instapaperComplete == true {
            successes += 1
        }
        if readabilityComplete == true {
            successes += 1
        }
        if pocketComplete == true {
            successes += 1
        }
        
        if (successes == successCount) {
            self.extensionContext?.completeRequestReturningItems(nil, completionHandler: nil)
        }

    }
    
}
