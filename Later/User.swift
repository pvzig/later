//
//  User.swift
//  Later
//
//  Created by Peter Zignego on 10/20/15.
//  Copyright © 2016 Launch Software. All rights reserved.
//

import Foundation

struct Later {
    static var defaults: UserDefaults {
        return UserDefaults(suiteName: "U63DWZL52M.com.launchsoft.later")!
    }
}

class User: NSObject {
    
    // MARK: - Instapaper
    static var instapaperAccount: Bool {
        get {
            return Later.defaults.bool(forKey: "instapaper")
        }
    }
    
    static var instapaperAccountName: String? {
        get {
            return Later.defaults.string(forKey: "instapaperAccountName")
        }
    }
    
    // MARK: - Pinboard
    static var pinboardAccount: Bool {
        get {
            return Later.defaults.bool(forKey: "pinboard")
        }
    }
    
    static var pinboardAccountName: String? {
        get {
            return Later.defaults.string(forKey: "pinboardAccountName")
        }
    }
    
    // MARK: - Pocket
    static var pocketAccount: Bool {
        get {
            return Later.defaults.bool(forKey: "pocket")
        }
    }
    
    static var pocketAccountName: String? {
        get {
            return Later.defaults.string(forKey: "pocketAccountName")
        }
    }

    // MARK: Utilities
    static func save() {
        Later.defaults.synchronize()
    }
}
