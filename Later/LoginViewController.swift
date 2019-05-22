//
//  LoginViewController.swift
//  Later
//
//  Created by Peter Zignego on 11/2/15.
//  Copyright © 2016 Launch Software. All rights reserved.
//

import Cocoa
import LaterKit

class LoginViewController: NSViewController {
 
    var loginType: AccountType?
    
    @IBOutlet var usernameField: NSTextField!
    @IBOutlet var passwordField: NSSecureTextField!
    @IBOutlet var passwordLabel: NSTextField!
    @IBOutlet var helpButton: NSButton!
    @IBOutlet var statusLabel: NSTextField!
    @IBOutlet var progressSpinner: NSProgressIndicator!
    
    override func viewDidAppear() {
        super.viewDidAppear()
        AppDelegate.sharedDelegate.eventMonitor?.stop()
    }
    
    override func viewDidDisappear() {
        super.viewDidDisappear()
        AppDelegate.sharedDelegate.eventMonitor?.start()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if loginType == .pinboard {
            passwordLabel.stringValue = "API Token:"
            helpButton.isHidden = false
        }
    }
    
    @IBAction func helpPressed(_ sender: NSButton) {
        let url = URL(string: "https://pinboard.in/settings/password")!
        NSWorkspace.shared.open(url)
    }
    
    @IBAction func cancelAction(_ sender: NSButton) {
        dismiss(self)
    }
    
    func dismiss() {
        if let vc = presentingViewController as? PopoverViewController {
            vc.configureUI()
        }
        dismiss(self)
    }
    
    @IBAction func loginButton(_ sender: NSButton) {
        statusLabel.stringValue = ""
        progressSpinner.startAnimation(sender)
        if let type = loginType {
            switch type {
            case .instapaper:
                Later.shared.login(
                    type: .instapaper,
                    username: usernameField.stringValue,
                    password: passwordField.stringValue,
                    success: {
                        self.progressSpinner.stopAnimation(self)
                        self.dismiss()
                }, failure: { errorMessage in
                    self.statusLabel.stringValue = errorMessage
                    self.progressSpinner.stopAnimation(self)

                })
            case .pinboard:
                Later.shared.login(
                    type: .pinboard,
                    username: usernameField.stringValue,
                    password: passwordField.stringValue,
                    success: {
                        self.progressSpinner.stopAnimation(self)
                        self.dismiss()
                }, failure: { errorMessage in
                    self.statusLabel.stringValue = errorMessage
                    self.progressSpinner.stopAnimation(self)
                })
            case .pocket:
                break
            }
        }
    }
}
