//
//  ViewController.swift
//  ShareToInstapaper
//
//  Created by Peter Zignego on 10/3/15.
//  Copyright © 2015 Launch Software. All rights reserved.
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
        if (User.sharedInstance.instapaperAccount == true) {
            connectToInstapaper.title = "Disconnect"
        } else {
            connectToInstapaper.title = "Connect"
        }
        
        if (User.sharedInstance.pocketAccount == true) {
            connectToPocket.title = "Disconnect"
        } else {
            connectToPocket.title = "Connect"
        }
        
        if (User.sharedInstance.readabilityAccount == true) {
            connectToReadability.title = "Disconnect"
        } else {
            connectToReadability.title = "Connect"
        }
    }
    
    func setLabelText() {
        if User.sharedInstance.instapaperAccount != true || User.sharedInstance.pocketAccount != true || User.sharedInstance.readabilityAccount != true {
            footerLabel.stringValue = "Connect your favorite read later service!"
        } else {
            footerLabel.stringValue = "Thanks for using Later!"
        }
    }
    
    @IBAction func instapaperAction(sender: NSButton) {
        if (User.sharedInstance.instapaperAccount == false) {
            let vc = LoginViewController(nibName: "LoginView", bundle: nil)!
            vc.loginType = AccountType.Instapaper
            presentViewControllerAsSheet(vc)
        } else {
            //let keychain = Keychain(service: "Read It Later Extension", accessGroup: "com.launchsoft.later")
            //keychain["instapaper-secret-token"] = ""
            //keychain["instapaper-oauth-token"] = ""
            NSUserDefaults(suiteName: "com.launchsoft.later")!.setBool(false, forKey: "instapaper")
            User.sharedInstance.save()
            setButtonTitles()
        }
    }
    
    @IBAction func pocketAction(sender: NSButton) {
        if (User.sharedInstance.pocketAccount == false) {
            PocketAPI.sharedAPI().loginWithHandler({(API: PocketAPI!, error: NSError!) -> Void in
                if (error != nil) {
                    
                } else {
                    PocketAPI.sharedAPI().enableKeychainSharingWithKeychainAccessGroup("com.launchsoft.later")
                    NSUserDefaults(suiteName: "com.launchsoft.later")!.setBool(true, forKey: "pocket")
                    User.sharedInstance.save()
                    self.setButtonTitles()
                }
            })
        } else {
            PocketAPI.sharedAPI().logout()
            NSUserDefaults(suiteName: "com.launchsoft.later")!.setBool(false, forKey: "pocket")
            User.sharedInstance.save()
            setButtonTitles()
        }
    }
    
    @IBAction func readabilityAction(sender: NSButton) {
        if (User.sharedInstance.readabilityAccount == false) {
            let vc = LoginViewController(nibName: "LoginView", bundle: nil)!
            vc.loginType = AccountType.Readability
            presentViewControllerAsSheet(vc)
        } else {
            //let keychain = Keychain(service: "Read It Later Extension", accessGroup: "com.launchsoft.later")
            //keychain["readability-secret-token"] = ""
            //keychain["readability-oauth-token"] = ""
            NSUserDefaults(suiteName: "com.launchsoft.later")!.setBool(false, forKey: "readability")
            User.sharedInstance.save()
            setButtonTitles()
        }
    }

    @IBAction func powerButton(sender: NSButton) {
        NSApplication.sharedApplication().terminate(self)
    }
    
}
