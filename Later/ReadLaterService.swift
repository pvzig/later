//
//  ReadLaterService.swift
//  Later
//
//  Created by Peter Zignego on 11/14/17.
//  Copyright © 2017 Launch Software. All rights reserved.
//

import Cocoa
import LaterKit

class ReadLaterService: NSObject {

    @objc func saveArticle(_ pasteboard: NSPasteboard, userData: String, error: AutoreleasingUnsafeMutablePointer<NSString>) {
        let items = pasteboard.pasteboardItems
        if let items = items, !items.isEmpty {
            for item in items {
                guard let data = item.data(forType: NSPasteboard.PasteboardType(rawValue: "public.rtf")) else { continue }
                do {
                    let attr = try NSAttributedString(data: data,
                                                      options: [.documentType: NSAttributedString.DocumentType.rtf],
                                                      documentAttributes: nil)
                    let attributes = attr.attributes(at: 0, longestEffectiveRange: nil, in: NSRange(location: 0, length: attr.length))
                    guard let url = attributes[NSAttributedStringKey.link] as? URL else { continue }
                    let title = item.string(forType: NSPasteboard.PasteboardType(rawValue: "public.utf8-plain-text"))
                    Later.shared.saveURL(url, title: title)
                } catch {}
            }
        }
    }
}
