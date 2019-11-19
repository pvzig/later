//
//  User.swift
//  Later
//
//  Created by Peter Zignego on 10/20/15.
//  Copyright © 2016 Launch Software. All rights reserved.
//

public class User: NSObject {
    private static let defaults = UserDefaults(suiteName: "U63DWZL52M.com.launchsoft.later")!

    private struct Keys {
        static let onboarding = "onboardingComplete"
    }

    // MARK: - Onboarding

    static public func setOnboardingComplete(_ complete: Bool) {
        UserDefaults.standard.set(complete, forKey: Keys.onboarding)
    }
    
    static public var isOnboardingComplete: Bool {
        return UserDefaults.standard.bool(forKey: Keys.onboarding)
    }

    // MARK: - Services

    static public func setAccount(_ type: AccountType) {
        defaults.set(true, forKey: type.accountKey)
    }

    static public func setAccountName(_ type: AccountType, account: String) {
        defaults.set(account, forKey: type.nameKey)
    }

    static public func hasAccount(_ type: AccountType) -> Bool {
        return defaults.bool(forKey: type.accountKey)
    }

    static public func accountName(_ type: AccountType) -> String? {
        return defaults.string(forKey: type.nameKey)
    }

    static public func removeService(_ type: AccountType) {
        defaults.removeObject(forKey: type.nameKey)
        defaults.removeObject(forKey: type.accountKey)
    }
}

@objc
public extension User {
    static var pocketAccountName: String? {
        return accountName(.pocket)
    }
}
