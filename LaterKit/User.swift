//
//  User.swift
//  Later
//
//  Created by Peter Zignego on 10/20/15.
//  Copyright © 2016 Launch Software. All rights reserved.
//

import Foundation

public class User: NSObject {
    static let defaults = UserDefaults(suiteName: "U63DWZL52M.com.launchsoft.later")!

    // MARK: - Onboarding
    static public func setOnboardingComplete() {
        UserDefaults.standard.set(true, forKey: "onboardingComplete")
    }
    
    static public var onboardingComplete: Bool {
        return UserDefaults.standard.bool(forKey: "onboardingComplete")
    }
    
    // MARK: - Instapaper
    static public var instapaperAccount: Bool {
        get {
            return defaults.bool(forKey: "instapaper")
        }
    }
    
    static var instapaperAccountName: String? {
        get {
            return defaults.string(forKey: "instapaperAccountName")
        }
    }
    
    // MARK: - Pinboard
    static public var pinboardAccount: Bool {
        get {
            return defaults.bool(forKey: "pinboard")
        }
    }
    
    static var pinboardAccountName: String? {
        get {
            return defaults.string(forKey: "pinboardAccountName")
        }
    }
    
    // MARK: - Pocket
    static public var pocketAccount: Bool {
        get {
            return defaults.bool(forKey: "pocket")
        }
    }
    
    @objc static var pocketAccountName: String? {
        get {
            return defaults.string(forKey: "pocketAccountName")
        }
    }

    // MARK: Utilities
    static public func pocketLoginSuccess() {
        defaults.set(true, forKey: "pocket")
        save()
    }

    static func save() {
        defaults.synchronize()
    }
}
