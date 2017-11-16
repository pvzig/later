//
//  LoginViewController.swift
//  Later
//
//  Created by Peter Zignego on 11/2/15.
//  Copyright © 2016 Launch Software. All rights reserved.
//

import Cocoa

class LoginViewController: NSViewController, IKEngineDelegate {
 
    var loginType: AccountType?
    
    @IBOutlet var usernameField: NSTextField!
    @IBOutlet var passwordField: NSSecureTextField!
    @IBOutlet var passwordLabel: NSTextField!
    @IBOutlet var helpButton: NSButton!
    @IBOutlet var statusLabel: NSTextField!
    @IBOutlet var progressSpinner: NSProgressIndicator!
    
    override func viewDidAppear() {
        (NSApplication.shared.delegate as? AppDelegate)?.eventMonitor?.stop()
    }
    
    override func viewDidDisappear() {
        (NSApplication.shared.delegate as? AppDelegate)?.eventMonitor?.start()
    }
    
    override func viewDidLoad() {
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
            case .pinboard:
                pinboardLogin()
            case .pocket:
                break
            }
        }
    }
    
    func pinboardLogin() {
        let user = usernameField.stringValue
        let token = passwordField.stringValue
        var components = URLComponents(string: "https://api.pinboard.in/v1/user/api_token")
        components?.queryItems = [
            URLQueryItem(name: "auth_token", value: "\(user):\(token)")
        ]
        guard let url = components?.url else {
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            DispatchQueue.main.async {
                guard let r = response as? HTTPURLResponse, r.statusCode == 200 else {
                    self.statusLabel.stringValue = "Pinboard API token validation failed."
                    self.progressSpinner.stopAnimation(nil)
                    return
                }
                Later.defaults.set(user, forKey: "pinboardAccountName")
                Later.defaults.set(true, forKey: "pinboard")
                Keychain.saveItem(token, account: user, service: "later-pinboard-api-token")
                User.save()
                self.progressSpinner.stopAnimation(nil)
                self.dismiss()
            }
        }.resume()
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
