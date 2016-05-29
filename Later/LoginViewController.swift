//
//  LoginViewController.swift
//  Later
//
//  Created by Peter Zignego on 11/2/15.
//  Copyright © 2015 Launch Software. All rights reserved.
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
    
    @IBAction func cancelAction(sender: NSButton) {
        dismissController(self)
    }
    
    func dismiss() {
        if let vc = presentingViewController as? ViewController {
            vc.setButtonTitles()
            vc.setLabelText()
        }
        dismissController(self)
    }
    
    @IBAction func loginButton(sender: NSButton) {
        statusLabel.stringValue = ""
        progressSpinner.startAnimation(sender)
        if let type = loginType {
            switch type {
            case .Instapaper:
                instapaperLogin()
                break
            case .Pocket:
                pocketLogin()
                break
            case .Readability:
                readabilityLogin()
                break
            }
        }
    }
    
    func instapaperLogin() {
        var client: IKEngine?
        IKEngine.setOAuthConsumerKey("3b21ad9ab01a4f85a557a36f59e70bf4", andConsumerSecret: "421d798d435c46b897f38c75cefce117")
        client = IKEngine(delegate: self)
        client?.authTokenForUsername(usernameField.stringValue, password: passwordField.stringValue, userInfo: nil)
        Later.defaults.setObject(usernameField.stringValue, forKey: "instapaperAccountName")
        User.save()
    }
    
    func pocketLogin() {
        
    }
    
    func readabilityLogin() {
        let headers = ["Authorization": "OAuth oauth_signature_method=PLAINTEXT, oauth_nonce=\(NSUUID().UUIDString), oauth_timestamp=\(String(Int(NSDate().timeIntervalSince1970))), oauth_consumer_key=ziggy444, oauth_consumer_secret=hdsZ7tTkMQLSdud7mEUYbL4SHyC7Wy4t, x_auth_username=\(usernameField.stringValue), x_auth_password=\(passwordField.stringValue), oauth_signature=hdsZ7tTkMQLSdud7mEUYbL4SHyC7Wy4t%26",
        ]

        Alamofire.request(.POST, "https://www.readability.com/api/rest/v1/oauth/access_token/", parameters: nil, encoding: .URL, headers: headers).response
            { response in
                if (response.1?.statusCode == 200) {
                    if let string = String(data: response.2!, encoding: NSUTF8StringEncoding) {
                        let strings = string.componentsSeparatedByString("=")
                        let secret = strings[1].componentsSeparatedByString("&")[0]
                        let oauth = strings[2].componentsSeparatedByString("&")[0]
                        let username = self.usernameField.stringValue
                        Keychain.saveItem(secret, account: username, service: "later-readability-secret-token")
                        Keychain.saveItem(oauth, account: username, service: "later-readability-oauth-token")
                        Later.defaults.setBool(true, forKey: "readability")
                        Later.defaults.setObject(username, forKey: "readabilityAccountName")
                        User.save()
                        self.progressSpinner.stopAnimation(nil)
                        self.dismiss()
                    }
                } else {
                    self.statusLabel.stringValue = "Readability login failed."
                    self.progressSpinner.stopAnimation(nil)
                }
        }
    }
    
    //MARK: IKEngineDelegate
    func engine(engine: IKEngine!, connection: IKURLConnection!, didReceiveAuthToken token: String!, andTokenSecret secret: String!) {
        engine.OAuthToken  = token
        engine.OAuthTokenSecret = secret
        if let account = User.instapaperAccountName {
            Keychain.saveItem(token, account: account, service: "later-instapaper-oauth-token")
            Keychain.saveItem(secret, account: account, service: "later-instapaper-secret-token")
            Later.defaults.setBool(true, forKey: "instapaper")
            User.save()
        }
        progressSpinner.stopAnimation(nil)
        dismiss()
    }
    
    func engine(engine: IKEngine!, didFailConnection connection: IKURLConnection!, error: NSError!) {
        statusLabel.stringValue = "Instapaper login failed."
        progressSpinner.stopAnimation(nil)
    }
    
}
