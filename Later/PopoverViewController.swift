//
//  ViewController.swift
//  ShareToInstapaper
//
//  Created by Peter Zignego on 10/3/15.
//  Copyright © 2016 Launch Software. All rights reserved.
//

import Cocoa
import LaterKit

class PopoverViewController: NSViewController {
    
    @IBOutlet var connectToInstapaper: NSButton!
    @IBOutlet var connectToPocket: NSButton!
    @IBOutlet var connectToPinboard: NSButton!
    
    @IBOutlet var footerLabel: NSTextField!
    
    private var aboutWindowController: NSWindowController!

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
    }

    public func configureUI() {
        setButtonTitles()
        setLabelText()
    }

    private func setButtonTitles() {
        connectToInstapaper.title = buttonLabelText(User.instapaperAccount)
        connectToPinboard.title = buttonLabelText(User.pinboardAccount)
        connectToPocket.title = buttonLabelText(User.pocketAccount)
    }
    
    private func buttonLabelText(_ account: Bool) -> String {
        if account {
            return "Disconnect"
        } else {
            return "Connect"
        }
    }
    
    private func setLabelText() {
        if User.instapaperAccount || User.pinboardAccount || User.pocketAccount {
            footerLabel.stringValue = "Thanks for using Later!"
        } else {
            footerLabel.stringValue = "Connect your favorite read later service!"
        }
    }
    
    @IBAction func instapaperAction(_ sender: NSButton) {
        if !User.instapaperAccount {
            let vc = LoginViewController(nibName: .LoginView, bundle: nil)
            vc.loginType = AccountType.instapaper
            presentViewControllerAsSheet(vc)
        } else {
            Later.shared.delete(type: .instapaper)
            setButtonTitles()
        }
    }
    
    @IBAction func pinboardAction(_ sender: NSButton) {
        if !User.pinboardAccount {
            let vc = LoginViewController(nibName: .LoginView, bundle: nil)
            vc.loginType = AccountType.pinboard
            presentViewControllerAsSheet(vc)
        } else {
            Later.shared.delete(type: .pinboard)
            setButtonTitles()
        }
    }
    
    @IBAction func pocketAction(_ sender: NSButton) {
        PocketAPI.shared().consumerKey = "47240-996424446c9727c03cfc1504"
        if !User.pocketAccount {
            PocketAPI.shared().login(handler: { (API: PocketAPI?, error: Error?) -> Void in
                if error != nil {
                    
                } else {
                    User.pocketLoginSuccess()
                    self.setButtonTitles()
                }
            })
        } else {
            PocketAPI.shared().logout()
            Later.shared.delete(type: .pocket)
            setButtonTitles()
        }
    }

    @IBAction func showSettingsMenu(_ sender: NSButton) {
        let menu = constructMenu()
        menu.popUp(positioning: menu.item(at: 0), at: NSEvent.mouseLocation, in: nil)
    }
    
    func constructMenu() -> NSMenu {
        let menu = NSMenu()
        let aboutItem = NSMenuItem(title: "About", action: #selector(PopoverViewController.about), keyEquivalent: "")
        let emailItem = NSMenuItem(title: "Support", action: #selector(PopoverViewController.email), keyEquivalent: "")
        let quitItem = NSMenuItem(title: "Quit", action: #selector(PopoverViewController.quit), keyEquivalent: "q")
        aboutItem.target = self
        emailItem.target = self
        quitItem.target = self
        menu.addItem(aboutItem)
        menu.addItem(emailItem)
        menu.addItem(quitItem)
        return menu
    }
    
    @objc func about() {
        aboutWindowController = NSWindowController(windowNibName: NSNib.Name(rawValue: "About"))
        aboutWindowController.showWindow(self)
        if let delegate = NSApplication.shared.delegate as? AppDelegate {
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

private extension NSNib.Name {
    static let LoginView = NSNib.Name(rawValue: "LoginView")
}
