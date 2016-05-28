//
//  Keychain.swift
//  Later
//
//  Created by Peter Zignego on 4/21/16.
//  Copyright © 2016 Launch Software. All rights reserved.
//

import Foundation
import Security

public struct Keychain {
 
    static let keychainPath = "Later.keychain"
    
    static func createKeychain() {
        // Create access
        let path = NSBundle.mainBundle().builtInPlugInsPath! + "/Read It Later.appex"
        var appExtension: SecTrustedApplication?
        var app: SecTrustedApplication?
        var access: SecAccessRef?
        SecTrustedApplicationCreateFromPath(path, &appExtension)
        SecTrustedApplicationCreateFromPath(nil, &app)
        SecAccessCreate("Read It Later Extension", NSArray(objects: app!, appExtension!), &access)
        // Create keychain
        var keychain: SecKeychain?
        SecKeychainCreate(keychainPath, 0, "", false, access, &keychain)
        SecKeychainOpen(keychainPath, &keychain)
    }

    static func saveItem(item: String, account: String, service: String) {
        
    }
    
    static func fetchItem(service: String, account: String) -> String {
        var length:UInt32 = 0
        var data:UnsafeMutablePointer<Void> = nil
        var ref: SecKeychainItemRef? = nil
        SecKeychainFindGenericPassword(nil,
                                       UInt32(service.characters.count),
                                       service,
                                       UInt32(account.characters.count),
                                       account,
                                       &length,
                                       &data,
                                       &ref)
        let item = NSString(bytes: UnsafePointer(data), length: Int(length), encoding: NSUTF8StringEncoding)!
        SecKeychainItemFreeContent(nil, data)
        return item as String
    }
}