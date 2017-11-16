//
//  ViewController.swift
//  ShareToInstapaper
//
//  Created by Peter Zignego on 10/3/15.
//  Copyright © 2016 Launch Software. All rights reserved.
//

import Cocoa

enum AccountType {
    case instapaper
    case pocket
    case pinboard
}

class ViewController: NSViewController {
    
    @IBOutlet var connectToInstapaper: NSButton!
    @IBOutlet var connectToPocket: NSButton!
    @IBOutlet var connectToPinboard: NSButton!
    
    @IBOutlet var footerLabel: NSTextField!
    
    var controller: NSWindowController?

    override func viewDidLoad() {
        super.viewDidLoad()
        setButtonTitles()
        setLabelText()
    }
    
    func setButtonTitles() {
        connectToInstapaper.title = buttonLabelText(User.instapaperAccount)
        connectToPinboard.title = buttonLabelText(User.pinboardAccount)
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
        if User.instapaperAccount == true || User.pinboardAccount == true || User.pocketAccount == true {
            footerLabel.stringValue = "Thanks for using Later!"
        } else {
            footerLabel.stringValue = "Connect your favorite read later service!"
        }
    }
    
    @IBAction func instapaperAction(_ sender: NSButton) {
        if (User.instapaperAccount == false) {
            let vc = LoginViewController(nibName: NSNib.Name(rawValue: "LoginView"), bundle: nil)
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
    
    @IBAction func pinboardAction(_ sender: NSButton) {
        if (User.pinboardAccount == false) {
            let vc = LoginViewController(nibName: NSNib.Name(rawValue: "LoginView"), bundle: nil)
            vc.loginType = AccountType.pinboard
            presentViewControllerAsSheet(vc)
        } else {
            if let account = User.pinboardAccountName {
                Keychain.removeItem("later-pinboard-api-token", account: account)
            }
            Later.defaults.set(false, forKey: "pinboard")
            Later.defaults.set(nil, forKey: "pinboardAccountName")
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
        menu.popUp(positioning: menu.item(at: 0), at: NSEvent.mouseLocation, in: nil)
    }
    
    func constructMenu() -> NSMenu {
        let menu = NSMenu()
        let aboutItem = NSMenuItem(title: "About", action: #selector(ViewController.about), keyEquivalent: "")
        let emailItem = NSMenuItem(title: "Support", action: #selector(ViewController.email), keyEquivalent: "")
        let quitItem = NSMenuItem(title: "Quit", action: #selector(ViewController.quit), keyEquivalent: "q")
        aboutItem.target = self
        emailItem.target = self
        quitItem.target = self
        menu.addItem(aboutItem)
        menu.addItem(emailItem)
        menu.addItem(quitItem)
        return menu
    }
    
    @objc func about() {
        controller = NSWindowController(windowNibName: NSNib.Name(rawValue: "About"))
        controller?.showWindow(nil)
        if let delegate = NSApplication.shared.delegate as? AppDelegate  {
            delegate.closePopover(self)
        }
    }
    
    @objc func email() {
        let url = URL(string: "mailto:peter@launchsoft.co?subject=Later%20Support")!
        NSWorkspace.shared.open(url)
    }
    
    @objc func quit() {
        NSApplication.shared.terminate(self)
    }
}
