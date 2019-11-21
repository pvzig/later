//
//  Keychain.swift
//  Later
//
//  Created by Peter Zignego on 4/21/16.
//  Copyright © 2016 Launch Software. All rights reserved.
//

import Security

public class LegacyKeychain: NSObject {
 
    @objc static func saveItem(_ item: String, account: String, service: String) {
        let path = Bundle.main.builtInPlugInsPath! + "/Read It Later.appex"
        var appExtension: SecTrustedApplication?
        var app: SecTrustedApplication?
        var access: SecAccess?
        SecTrustedApplicationCreateFromPath(path, &appExtension)
        SecTrustedApplicationCreateFromPath(nil, &app)
        SecAccessCreate("Read It Later Extension" as CFString, NSArray(objects: app!, appExtension!), &access)
        let s = UnsafeMutablePointer<Int8>(mutating: (service as NSString).utf8String)
        let a = UnsafeMutablePointer<Int8>(mutating: (account as NSString).utf8String)
        let kind = UnsafeMutablePointer<Int8>(mutating: ("application password" as NSString).utf8String)
        let attrs = [
            SecKeychainAttribute(tag: SecItemAttr.serviceItemAttr.rawValue, length: UInt32(strlen(service)), data: s!),
            SecKeychainAttribute(tag: SecItemAttr.descriptionItemAttr.rawValue, length: UInt32(strlen("application password")), data: kind!),
            SecKeychainAttribute(tag: SecItemAttr.accountItemAttr.rawValue, length: UInt32(strlen(account)), data: a!)
        ]
        var attributes = SecKeychainAttributeList(count: UInt32(attrs.count), attr: UnsafeMutablePointer<SecKeychainAttribute>(mutating: attrs))
        var ref: SecKeychainItem? = nil
        SecKeychainItemCreateFromContent(.genericPasswordItemClass,
                                         &attributes,
                                         UInt32(strlen(item)),
                                         item,
                                         nil,
                                         access,
                                         &ref)
    }
    
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
