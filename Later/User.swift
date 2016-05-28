//
//  User.swift
//  Later
//
//  Created by Peter Zignego on 10/20/15.
//  Copyright © 2015 Launch Software. All rights reserved.
//

import Foundation

class User: NSObject {
    
    static let sharedInstance = User()
    
    var instapaperAccount: Bool {
        get {
            let defaults = NSUserDefaults(suiteName: "com.launchsoft.later")!
            return defaults.boolForKey("instapaper")
        }
    }
    var pocketAccount: Bool {
        get {
            let defaults = NSUserDefaults(suiteName: "com.launchsoft.later")!
            return defaults.boolForKey("pocket")
        }
    }
    
    // MARK: Readability
    var readabilityAccount: Bool {
        get {
            let defaults = NSUserDefaults(suiteName: "com.launchsoft.later")!
            return defaults.boolForKey("readability")
        }
    }
    
    var readabilityAccountName: String? {
        get {
            let defaults = NSUserDefaults(suiteName: "com.launchsoft.later")!
            return defaults.stringForKey("readabilityAccountName")
        }
    }
    
    // MARK: Utilities
    func save() {
        let defaults = NSUserDefaults(suiteName: "com.launchsoft.later")!
        defaults.synchronize()
    }

}
