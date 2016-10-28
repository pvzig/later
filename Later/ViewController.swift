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
    case instapaper
    case pocket
}

class ViewController: NSViewController {
    
    @IBOutlet var connectToInstapaper: NSButton!
    @IBOutlet var connectToPocket: NSButton!
    @IBOutlet var footerLabel: NSTextField!
    
    var controller: NSWindowController?

    override func viewDidLoad() {
        super.viewDidLoad()
        setButtonTitles()
        setLabelText()
    }
    
    func setButtonTitles() {
        connectToInstapaper.title = buttonLabelText(User.instapaperAccount)
        connectToPocket.title = buttonLabelText(User.pocketAccount)
    }
    
    func buttonLabelText(_ account: Bool) -> String {
        if account == true {
            return "Disconnect"
        } else {
           return "Connect"
        }
    }
    
    func setLabelText() {
        if User.instapaperAccount == true || User.pocketAccount == true {
            footerLabel.stringValue = "Thanks for using Later!"
        } else {
            footerLabel.stringValue = "Connect your favorite read later service!"
        }
    }
    
    @IBAction func instapaperAction(_ sender: NSButton) {
        if (User.instapaperAccount == false) {
            let vc = LoginViewController(nibName: "LoginView", bundle: nil)!
            vc.loginType = AccountType.instapaper
            presentViewControllerAsSheet(vc)
        } else {
            if let account = User.instapaperAccountName {
                Keychain.removeItem("later-instapaper-oauth-token", account: account)
                Keychain.removeItem("later-instapaper-secret-token", account: account)
            }
            Later.defaults.set(false, forKey: "instapaper")
            Later.defaults.set(nil, forKey: "instapaperAccountName")
            User.save()
            setButtonTitles()
        }
    }
    
    @IBAction func pocketAction(_ sender: NSButton) {
        PocketAPI.shared().consumerKey = "47240-996424446c9727c03cfc1504"
        if (User.pocketAccount == false) {
            PocketAPI.shared().login(handler: {(API: PocketAPI?, error: Error?) -> Void in
                if (error != nil) {
                    
                } else {
                    Later.defaults.set(true, forKey: "pocket")
                    User.save()
                    self.setButtonTitles()
                }
            })
        } else {
            PocketAPI.shared().logout()
            Later.defaults.set(false, forKey: "pocket")
            User.save()
            setButtonTitles()
        }
    }

    @IBAction func showSettingsMenu(_ sender: NSButton) {
        let menu = constructMenu()
        menu.popUp(positioning: menu.item(at: 0), at: NSEvent.mouseLocation(), in: nil)
    }
    
    func constructMenu() -> NSMenu {
        let menu = NSMenu()
        let aboutItem = NSMenuItem(title: "About", action: #selector(ViewController.about), keyEquivalent: "")
        let quitItem = NSMenuItem(title: "Quit", action: #selector(ViewController.quit), keyEquivalent: "q")
        aboutItem.target = self
        quitItem.target = self
        menu.addItem(aboutItem)
        menu.addItem(quitItem)
        return menu
    }
    
    func about() {
        controller = NSWindowController(windowNibName: "About")
        controller?.showWindow(nil)
        if let delegate = NSApplication.shared().delegate as? AppDelegate  {
            delegate.closePopover(self)
        }
    }
    
    func quit() {
        NSApplication.shared().terminate(self)
    }
}
