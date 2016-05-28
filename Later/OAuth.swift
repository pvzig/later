//
//  OAuth.swift
//  Later
//
//  Created by Peter Zignego on 11/19/15.
//  Copyright © 2015 Launch Software. All rights reserved.
//

import Foundation

class OAuth: NSObject {
    
    static func authorizationHeaderForMethod(method: String, url: NSURL, parameters: Dictionary<String, Any>, isMediaUpload: Bool) -> String {
        
        let oauth = Keychain.fetchItem("later-readability-oauth-token", account: User.sharedInstance.readabilityAccountName!)
        let secret = Keychain.fetchItem("later-readability-secret-token", account: User.sharedInstance.readabilityAccountName!)
        
        var authorizationParameters = Dictionary<String, Any>()
        authorizationParameters["oauth_version"] = "1.0"
        authorizationParameters["oauth_signature_method"] =  "HMAC-SHA1"
        authorizationParameters["oauth_consumer_key"] = "ziggy444"
        authorizationParameters["oauth_timestamp"] = String(Int(NSDate().timeIntervalSince1970))
        authorizationParameters["oauth_nonce"] = NSUUID().UUIDString
        authorizationParameters["oauth_token"] = oauth
        
        for (key, value): (String, Any) in parameters {
            if key.hasPrefix("oauth_") {
                authorizationParameters.updateValue(value, forKey: key)
            }
        }
        
        let combinedParameters = authorizationParameters +| parameters
        
        let finalParameters = isMediaUpload ? authorizationParameters : combinedParameters
        
        authorizationParameters["oauth_signature"] = self.oauthSignatureForMethod(method, url: url, parameters: finalParameters, OAuthToken: oauth, secretToken: secret)
        
        var authorizationParameterComponents = authorizationParameters.urlEncodedQueryStringWithEncoding(NSUTF8StringEncoding).componentsSeparatedByString("&") as [String]
        authorizationParameterComponents.sortInPlace { $0 < $1 }
        
        var headerComponents = [String]()
        for component in authorizationParameterComponents {
            let subcomponent = component.componentsSeparatedByString("=") as [String]
            if subcomponent.count == 2 {
                headerComponents.append("\(subcomponent[0])=\"\(subcomponent[1])\"")
            }
        }
        
        return "OAuth " + headerComponents.joinWithSeparator(", ")
    }
    
    static func oauthSignatureForMethod(method: String, url: NSURL, parameters: Dictionary<String, Any>, OAuthToken: String, secretToken: String) -> String {
        var tokenSecret: NSString = ""
        tokenSecret = secretToken.urlEncodedStringWithEncoding(NSUTF8StringEncoding)
        
        let encodedConsumerSecret = "hdsZ7tTkMQLSdud7mEUYbL4SHyC7Wy4t".urlEncodedStringWithEncoding(NSUTF8StringEncoding)
        
        let signingKey = "\(encodedConsumerSecret)&\(tokenSecret)"
        
        var parameterComponents = parameters.urlEncodedQueryStringWithEncoding(NSUTF8StringEncoding).componentsSeparatedByString("&") as [String]
        parameterComponents.sortInPlace { $0 < $1 }
        
        let parameterString = parameterComponents.joinWithSeparator("&")
        let encodedParameterString = parameterString.urlEncodedStringWithEncoding(NSUTF8StringEncoding)
        
        let encodedURL = url.absoluteString.urlEncodedStringWithEncoding(NSUTF8StringEncoding)
        
        let signatureBaseString = "\(method)&\(encodedURL)&\(encodedParameterString)"
        
        // let signature = signatureBaseString.SHA1DigestWithKey(signingKey)
        
        return signatureBaseString.SHA1DigestWithKey(signingKey).base64EncodedStringWithOptions([])
    }
    
}