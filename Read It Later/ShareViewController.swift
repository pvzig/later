//
//  ShareViewController.swift
//  Read It Later
//
//  Created by Peter Zignego on 11/14/15.
//  Copyright © 2015 Launch Software. All rights reserved.
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
        if (User.sharedInstance.instapaperAccount == true) {
            addToInstapaper(url)
        }
        if (User.sharedInstance.readabilityAccount == true) {
            addToReadability(url)
        }
        if (User.sharedInstance.pocketAccount == true) {
            addToPocket(url)
        }
        if User.sharedInstance.instapaperAccount == false &&
            User.sharedInstance.readabilityAccount == false &&
            User.sharedInstance.pocketAccount == false {
                completionHandler()
        }
    }
    
    func addToInstapaper(url: NSURL) {
        IKEngine.setOAuthConsumerKey("3b21ad9ab01a4f85a557a36f59e70bf4", andConsumerSecret: "421d798d435c46b897f38c75cefce117")
        client = IKEngine(delegate: self)
        //let keychain = Keychain(service: "Read It Later Extension", accessGroup: "com.launchsoft.later")
        //client?.OAuthToken = keychain["instapaper-oauth-token"]
        //client?.OAuthTokenSecret = keychain["instapaper-secret-token"]
        client?.addBookmarkWithURL(url, userInfo: nil)
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
        PocketAPI.sharedAPI().keychainAccessGroup = "com.launchsoft.later"
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
        if (User.sharedInstance.instapaperAccount == true) {
            successCount += 1
        }
        if (User.sharedInstance.readabilityAccount == true) {
            successCount += 1
        }
        if (User.sharedInstance.pocketAccount == true) {
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
