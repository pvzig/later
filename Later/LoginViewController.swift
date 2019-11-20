//
//  LoginViewController.swift
//  Later
//
//  Created by Peter Zignego on 11/2/15.
//  Copyright © 2016 Launch Software. All rights reserved.
//

import LaterKit

class LoginViewController: NSViewController {
     
    @IBOutlet var usernameField: NSTextField!
    @IBOutlet var passwordField: NSSecureTextField!
    @IBOutlet var passwordLabel: NSTextField!
    @IBOutlet var helpButton: NSButton!
    @IBOutlet var statusLabel: NSTextField!
    @IBOutlet var progressSpinner: NSProgressIndicator!
    
    let loginType: AccountType
    
    init(loginType: AccountType) {
        self.loginType = loginType
        super.init(nibName: "LoginView", bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
        if let vc = presentingViewController as? MainViewController {
            vc.configureUI()
        }
        dismiss(self)
    }
    
    @IBAction func loginButton(_ sender: NSButton) {
        statusLabel.stringValue = ""
        progressSpinner.startAnimation(sender)
        switch loginType {
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
