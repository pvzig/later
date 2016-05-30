//
//  Keychain.swift
//  Later
//
//  Created by Peter Zignego on 4/21/16.
//  Copyright © 2016 Launch Software. All rights reserved.
//

import Foundation
import Security

public class Keychain: NSObject {
 
    static func saveItem(item: String, account: String, service: String) {
        let path = NSBundle.mainBundle().builtInPlugInsPath! + "/Read It Later.appex"
        var appExtension: SecTrustedApplication?
        var app: SecTrustedApplication?
        var access: SecAccessRef?
        SecTrustedApplicationCreateFromPath(path, &appExtension)
        SecTrustedApplicationCreateFromPath(nil, &app)
        SecAccessCreate("Read It Later Extension", NSArray(objects: app!, appExtension!), &access)
        let s = UnsafeMutablePointer<Int8>((service as NSString).UTF8String)
        let a = UnsafeMutablePointer<Int8>((account as NSString).UTF8String)
        let kind = UnsafeMutablePointer<Int8>(("application password" as NSString).UTF8String)
        let attrs = [
            SecKeychainAttribute(tag: SecItemAttr.ServiceItemAttr.rawValue, length: UInt32(strlen(service)), data: s),
            SecKeychainAttribute(tag: SecItemAttr.DescriptionItemAttr.rawValue, length: UInt32(strlen("application password")), data: kind),
            SecKeychainAttribute(tag: SecItemAttr.AccountItemAttr.rawValue, length: UInt32(strlen(account)), data: a)
        ]
        var attributes = SecKeychainAttributeList(count: UInt32(attrs.count), attr: UnsafeMutablePointer<SecKeychainAttribute>(attrs))
        var ref: SecKeychainItemRef? = nil
        SecKeychainItemCreateFromContent(.GenericPasswordItemClass,
                                         &attributes,
                                         UInt32(strlen(item)),
                                         item,
                                         nil,
                                         access,
                                         &ref)
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
    
    static func removeItem(service: String, account: String) {
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
        guard let item = ref else {
            return
        }
        SecKeychainItemDelete(item)
    }
}