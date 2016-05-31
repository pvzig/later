//
//  ViewController.swift
//  ShareToInstapaper
//
//  Created by Peter Zignego on 10/3/15.
//  Copyright © 2016 Launch Software. All rights reserved.
//

import Cocoa
import Alamofire

enum AccountType {
    case Instapaper
    case Pocket
    case Readability
}

class ViewController: NSViewController {
    
    @IBOutlet var connectToInstapaper: NSButton!
    @IBOutlet var connectToPocket: NSButton!
    @IBOutlet var connectToReadability: NSButton!
    @IBOutlet var footerLabel: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setButtonTitles()
        setLabelText()
    }
    
    func setButtonTitles() {
        connectToInstapaper.title = buttonLabelText(User.instapaperAccount)
        connectToPocket.title = buttonLabelText(User.pocketAccount)
        connectToReadability.title = buttonLabelText(User.readabilityAccount)
    }
    
    func buttonLabelText(account: Bool) -> String {
        if account == true {
            return "Disconnect"
        } else {
           return "Connect"
        }
    }
    
    func setLabelText() {
        if User.instapaperAccount != true || User.pocketAccount != true || User.readabilityAccount != true {
            footerLabel.stringValue = "Connect your favorite read later service!"
        } else {
            footerLabel.stringValue = "Thanks for using Later!"
        }
    }
    
    @IBAction func instapaperAction(sender: NSButton) {
        if (User.instapaperAccount == false) {
            let vc = LoginViewController(nibName: "LoginView", bundle: nil)!
            vc.loginType = AccountType.Instapaper
            presentViewControllerAsSheet(vc)
        } else {
            if let account = User.instapaperAccountName {
                Keychain.removeItem("later-instapaper-oauth-token", account: account)
                Keychain.removeItem("later-instapaper-secret-token", account: account)
            }
            Later.defaults.setBool(false, forKey: "instapaper")
            Later.defaults.setObject(nil, forKey: "instapaperAccountName")
            User.save()
            setButtonTitles()
        }
    }
    
    @IBAction func pocketAction(sender: NSButton) {
        PocketAPI.sharedAPI().consumerKey = "47240-996424446c9727c03cfc1504"
        if (User.pocketAccount == false) {
            PocketAPI.sharedAPI().loginWithHandler({(API: PocketAPI!, error: NSError!) -> Void in
                if (error != nil) {
                    
                } else {
                    Later.defaults.setBool(true, forKey: "pocket")
                    User.save()
                    self.setButtonTitles()
                }
            })
        } else {
            PocketAPI.sharedAPI().logout()
            Later.defaults.setBool(false, forKey: "pocket")
            User.save()
            setButtonTitles()
        }
    }
    
    @IBAction func readabilityAction(sender: NSButton) {
        if (User.readabilityAccount == false) {
            let vc = LoginViewController(nibName: "LoginView", bundle: nil)!
            vc.loginType = AccountType.Readability
            presentViewControllerAsSheet(vc)
        } else {
            if let account = User.readabilityAccountName {
                Keychain.removeItem("later-readability-oauth-token", account: account)
                Keychain.removeItem("later-readability-secret-token", account: account)
            }
            Later.defaults.setBool(false, forKey: "readability")
            Later.defaults.setObject(nil, forKey: "readabilityAccountName")
            User.save()
            setButtonTitles()
        }
    }

    @IBAction func powerButton(sender: NSButton) {
        NSApplication.sharedApplication().terminate(self)
    }
    
}
