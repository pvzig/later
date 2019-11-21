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
        if User.isOnboardingComplete {
            // Migration for 1.2.0
            Later.shared.migrate()
        } else {
            presentAsModalWindow(OnboardingViewController(nibName: "OnboardingView", bundle: nil))
        }
        configureUI()
    }
    
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
    
    // MARK: - Menu commands
    
    @IBAction func showAboutWindow(_ sender: NSMenuItem) {
        let aboutWindow = NSWindowController(windowNibName: "About")
        aboutWindow.showWindow(self)
    }
    
    @IBAction func emailSupport(_ sender: NSMenuItem) {
        let url = URL(string: "mailto:peter@launchsoft.co?subject=Later%20Support")!
        NSWorkspace.shared.open(url)
    }
    
    @IBAction func showResetModal(_ sender: NSMenuItem) {
        let alert = NSAlert()
        alert.messageText = "Reset All Accounts?"
        alert.informativeText = "Resetting your accounts will log out of all services and clear Later's application data."
        alert.addButton(withTitle: "Reset All Accounts")
        alert.addButton(withTitle: "Cancel")
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            Later.shared.reset()
            configureUI()
        }
    }
}
