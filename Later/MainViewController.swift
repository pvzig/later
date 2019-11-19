//
//  ViewController.swift
//  ShareToInstapaper
//
//  Created by Peter Zignego on 10/3/15.
//  Copyright © 2016 Launch Software. All rights reserved.
//

import LaterKit

class MainViewController: NSViewController {

    @IBOutlet var connectToInstapaper: NSButton!
    @IBOutlet var connectToPocket: NSButton!
    @IBOutlet var connectToPinboard: NSButton!
    @IBOutlet var footerLabel: NSTextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
    }

    public func configureUI() {
        setButtonTitles()
        setLabelText()
    }

    private func setButtonTitles() {
        connectToInstapaper.title = buttonLabelText(User.hasAccount(.instapaper))
        connectToPinboard.title = buttonLabelText(User.hasAccount(.pinboard))
        connectToPocket.title = buttonLabelText(User.hasAccount(.pocket))
    }
    
    private func buttonLabelText(_ account: Bool) -> String {
        if account {
            return "Disconnect"
        } else {
            return "Connect"
        }
    }
    
    private func setLabelText() {
        if User.hasAccount(.instapaper) || User.hasAccount(.pinboard) || User.hasAccount(.pocket) {
            footerLabel.stringValue = "Thanks for using Later!"
        } else {
            footerLabel.stringValue = "Connect your favorite read later service!"
        }
    }
    
    @IBAction func instapaperAction(_ sender: NSButton) {
        if !User.hasAccount(.instapaper) {
            let vc = LoginViewController(nibName: "LoginView", bundle: .main)
            vc.loginType = .instapaper
            presentAsSheet(vc)
        } else {
            Later.shared.delete(type: .instapaper)
            setButtonTitles()
        }
    }
    
    @IBAction func pinboardAction(_ sender: NSButton) {
        if !User.hasAccount(.pinboard) {
            let vc = LoginViewController(nibName: "LoginView", bundle: nil)
            vc.loginType = .pinboard
            presentAsSheet(vc)
        } else {
            Later.shared.delete(type: .pinboard)
            setButtonTitles()
        }
    }
    
    @IBAction func pocketAction(_ sender: NSButton) {
        PocketAPI.shared().consumerKey = "47240-996424446c9727c03cfc1504"
        if !User.hasAccount(.pocket) {
            PocketAPI.shared().login(handler: { (API: PocketAPI?, error: Error?) -> Void in
                if error != nil {
                    
                } else {
                    User.setAccount(.pocket)
                    self.setButtonTitles()
                }
            })
        } else {
            PocketAPI.shared().logout()
            Later.shared.delete(type: .pocket)
            setButtonTitles()
        }
    }
    
    @IBAction func showAboutWindow(_ sender: NSMenuItem) {
        let aboutWindow = NSWindowController(windowNibName: "About")
        aboutWindow.showWindow(self)
    }
    
    @objc func email() {
        let url = URL(string: "mailto:peter@launchsoft.co?subject=Later%20Support")!
        NSWorkspace.shared.open(url)
    }
}
