//
//  User.swift
//  Later
//
//  Created by Peter Zignego on 10/20/15.
//  Copyright © 2016 Launch Software. All rights reserved.
//

import KeychainAccess

public class User: NSObject {
    private static let defaults = UserDefaults(suiteName: "U63DWZL52M.com.launchsoft.later")!

    private struct Keys {
        static let onboarding = "onboardingComplete"
    }

    // MARK: - Onboarding
    
    public static var isOnboardingComplete: Bool {
        get {
            UserDefaults.standard.bool(forKey: Keys.onboarding)
        }
        set (newValue) {
            UserDefaults.standard.set(newValue, forKey: Keys.onboarding)
        }
    }
    
    public static var isAccountAdded: Bool {
        return hasAccount(.instapaper) || hasAccount(.pinboard) || hasAccount(.pocket)
    }

    // MARK: - Services
    
    public static func hasAccount(_ type: AccountType) -> Bool {
        switch type {
        case .instapaper:
            return Later.shared.keychain[Later.Constants.Instapaper.oauthToken] != nil
        case .pocket:
            return Later.shared.keychain[Later.Constants.Pocket.tokenKey] != nil
        case .pinboard:
            return Later.shared.keychain[Later.Constants.Pinboard.apiToken] != nil
        }
    }
}

// Interface with the Obj-C Pocket SDK
extension User {
    
    private struct Constants {
        static let key = "pocketAccountName"
    }
    
    @objc static var pocketAccountName: String? {
        return defaults.string(forKey: Constants.key)
    }
    
    @objc static func setPocketAccountName(_ name: String) {
        defaults.set(name, forKey: Constants.key)
    }
    
    @objc static var pocketToken: String? {
        return Later.shared.keychain[Later.Constants.Pocket.tokenKey]
    }
    
    @objc static func setPocketToken(_ value: String) {
        Later.shared.keychain[Later.Constants.Pocket.tokenKey] = value
    }
    
    @objc static var pocketTokenDigest: String? {
        return Later.shared.keychain[Later.Constants.Pocket.tokenDigestKey]
    }
    
    @objc static func setPocketTokenDigest(_ value: String) {
        Later.shared.keychain[Later.Constants.Pocket.tokenDigestKey] = value
    }
    
    @objc static func pocketLogout() {
        try? Later.shared.keychain.remove(Later.Constants.Pocket.tokenKey)
        try? Later.shared.keychain.remove(Later.Constants.Pocket.tokenDigestKey)
        defaults.removeObject(forKey: Constants.key)
    }
}
