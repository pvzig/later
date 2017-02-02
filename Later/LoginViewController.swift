//
//  LoginViewController.swift
//  Later
//
//  Created by Peter Zignego on 11/2/15.
//  Copyright © 2016 Launch Software. All rights reserved.
//

import Cocoa
import Alamofire

class LoginViewController: NSViewController, IKEngineDelegate {
 
    var loginType: AccountType?
    
    @IBOutlet var usernameField: NSTextField!
    @IBOutlet var passwordField: NSSecureTextField!
    @IBOutlet var statusLabel: NSTextField!
    @IBOutlet var progressSpinner: NSProgressIndicator!
    
    override func viewDidLoad() {
        
    }
    
    @IBAction func cancelAction(_ sender: NSButton) {
        self.dismiss(self)
    }
    
    func dismiss() {
        if let vc = presenting as? ViewController {
            vc.setButtonTitles()
            vc.setLabelText()
        }
        self.dismiss(self)
    }
    
    @IBAction func loginButton(_ sender: NSButton) {
        statusLabel.stringValue = ""
        progressSpinner.startAnimation(sender)
        if let type = loginType {
            switch type {
            case .instapaper:
                instapaperLogin()
            case .pocket:
                break
            }
        }
    }
    
    func instapaperLogin() {
        var client: IKEngine?
        IKEngine.setOAuthConsumerKey("3b21ad9ab01a4f85a557a36f59e70bf4", andConsumerSecret: "421d798d435c46b897f38c75cefce117")
        client = IKEngine(delegate: self)
        _ = client?.authToken(forUsername: usernameField.stringValue, password: passwordField.stringValue, userInfo: nil)
        Later.defaults.set(usernameField.stringValue, forKey: "instapaperAccountName")
        User.save()
    }
    
    //MARK: IKEngineDelegate
    func engine(_ engine: IKEngine!, connection: IKURLConnection!, didReceiveAuthToken token: String!, andTokenSecret secret: String!) {
        engine.oAuthToken  = token
        engine.oAuthTokenSecret = secret
        if let account = User.instapaperAccountName {
            Keychain.saveItem(token, account: account, service: "later-instapaper-oauth-token")
            Keychain.saveItem(secret, account: account, service: "later-instapaper-secret-token")
            Later.defaults.set(true, forKey: "instapaper")
            User.save()
        }
        progressSpinner.stopAnimation(nil)
        dismiss()
    }
    
    func engine(_ engine: IKEngine!, didFail connection: IKURLConnection!, error: Error!) {
        statusLabel.stringValue = "Instapaper login failed."
        progressSpinner.stopAnimation(nil)
    }    
}
