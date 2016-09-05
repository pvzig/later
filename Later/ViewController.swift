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
    case Pinboard
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
        connectToPocket.title = buttonLabelText(User.pocketAccount)
        connectToPocket.title = buttonLabelText(User.pinboardAccount)
    }
    
    func buttonLabelText(account: Bool) -> String {
        if account == true {
            return "Disconnect"
        } else {
           return "Connect"
        }
    }
    
    func setLabelText() {
        if User.instapaperAccount == true || User.pocketAccount == true || User.pinboardAccount == true {
            footerLabel.stringValue = "Thanks for using Later!"
        } else {
            footerLabel.stringValue = "Connect your favorite read later service!"
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
    
    //TODO: - Pinboard login
    @IBAction func pinboardAction(sender: NSButton) {
        
    }
    
    @IBAction func showSettingsMenu(sender: NSButton) {
        let menu = constructMenu()
        menu.popUpMenuPositioningItem(menu.itemAtIndex(0), atLocation: NSEvent.mouseLocation(), inView: nil)
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
        if let delegate = NSApplication.sharedApplication().delegate as? AppDelegate  {
            delegate.closePopover(self)
        }
    }
    
    func quit() {
        NSApplication.sharedApplication().terminate(self)
    }
    
}
