//
//  User.swift
//  Later
//
//  Created by Peter Zignego on 10/20/15.
//  Copyright © 2015 Launch Software. All rights reserved.
//

import Foundation

struct Later {
    static var defaults: NSUserDefaults {
        return NSUserDefaults(suiteName: "com.launchsoft.later")!
    }
}

class User: NSObject {
    
    // MARK: - Instapaper
    static var instapaperAccount: Bool {
        get {
            return Later.defaults.boolForKey("instapaper")
        }
    }
    
    static var instapaperAccountName: String? {
        get {
            return Later.defaults.stringForKey("instapaperAccountName")
        }
    }
    
    // MARK: - Pocket
    static var pocketAccount: Bool {
        get {
            return Later.defaults.boolForKey("pocket")
        }
    }
    
    static var pocketAccountName: String? {
        get {
            return Later.defaults.stringForKey("pocketAccountName")
        }
    }
    
    // MARK: - Readability
    static var readabilityAccount: Bool {
        get {
            return Later.defaults.boolForKey("readability")
        }
    }
    
    static var readabilityAccountName: String? {
        get {
            return Later.defaults.stringForKey("readabilityAccountName")
        }
    }
    
    // MARK: Utilities
    static func save() {
        Later.defaults.synchronize()
    }

}
