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
        
        if !User.isOnboardingComplete {
            let window = NSWindow(contentViewController: OnboardingViewController(nibName: "OnboardingView", bundle: nil))
            window.titleVisibility = .hidden
            window.styleMask.remove(.resizable)
            window.styleMask.remove(.miniaturizable)
            let windowController = NSWindowController(window: window)
            windowController.showWindow(self)
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(configureUI), name: .updateUI, object: nil)
    }
    
    @objc
    func configureUI() {
        setButtonTitles()
        setLabelText()
    }

    private func setButtonTitles() {
        connectToInstapaper.title = buttonLabelText(User.hasAccount(.instapaper))
        connectToPinboard.title = buttonLabelText(User.hasAccount(.pinboard))
        connectToPocket.title = buttonLabelText(User.hasAccount(.pocket))
    }
    
    private func buttonLabelText(_ account: Bool) -> String {
        return account ? "Disconnect" : "Connect"
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
            present(LoginViewController(loginType: .instapaper), asPopoverRelativeTo: connectToInstapaper.frame, of: view, preferredEdge: .maxX, behavior: .semitransient)
        } else {
            Later.shared.delete(type: .instapaper)
            setButtonTitles()
        }
    }
    
    @IBAction func pinboardAction(_ sender: NSButton) {
        if !User.hasAccount(.pinboard) {
            present(LoginViewController(loginType: .pinboard), asPopoverRelativeTo: connectToPinboard.frame, of: view, preferredEdge: .maxX, behavior: .semitransient)
        } else {
            Later.shared.delete(type: .pinboard)
            setButtonTitles()
        }
    }
    
    @IBAction func pocketAction(_ sender: NSButton) {
        if !User.hasAccount(.pocket) {
            // Username and password are gathered by the web ui flow
            Later.shared.login(type: .pocket, username: "", password: "", success: {
                self.setButtonTitles()
            }) { error in
                self.setButtonTitles()
            }
        } else {
            PocketAPI.shared().logout()
            Later.shared.delete(type: .pocket)
            setButtonTitles()
        }
    }
}
