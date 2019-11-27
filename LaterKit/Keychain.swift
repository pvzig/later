//
//  Keychain.swift
//  Later
//
//  Created by Peter Zignego on 4/21/16.
//  Copyright © 2016 Launch Software. All rights reserved.
//

import Security

public class LegacyKeychain: NSObject {
    
    @objc static func fetchItem(_ service: String, account: String) -> String? {
        var length:UInt32 = 0
        var data:UnsafeMutableRawPointer? = nil
        var ref: SecKeychainItem? = nil
        SecKeychainFindGenericPassword(nil,
                                       UInt32(service.count),
                                       service,
                                       UInt32(account.count),
                                       account,
                                       &length,
                                       &data,
                                       &ref)
        guard let bytes = UnsafeMutableRawPointer(data) else {
            SecKeychainItemFreeContent(nil, data)
            return nil
        }
        let item = NSString(bytes: bytes, length: Int(length), encoding: String.Encoding.utf8.rawValue)!
        SecKeychainItemFreeContent(nil, data)
        return item as String
    }
    
    @objc static func removeItem(_ service: String, account: String) {
        var length:UInt32 = 0
        var data:UnsafeMutableRawPointer? = nil
        var ref: SecKeychainItem? = nil
        SecKeychainFindGenericPassword(nil,
                                       UInt32(service.count),
                                       service,
                                       UInt32(account.count),
                                       account,
                                       &length,
                                       &data,
                                       &ref)
        guard let item = ref else {
            return
        }
        SecKeychainItemDelete(item)
    }
}
