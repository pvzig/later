//
//  ReadLaterService.swift
//  Later
//
//  Created by Peter Zignego on 11/14/17.
//  Copyright © 2017 Launch Software. All rights reserved.
//

import Cocoa

class ReadLaterService: NSObject {

    let errorMessage = NSString(string: "Could not save URL.")

    @objc func saveArticle(_ pboard: NSPasteboard, userData: String, error: AutoreleasingUnsafeMutablePointer<NSString>) {
        guard let str = pboard.string(forType: NSPasteboard.PasteboardType.string) else {
            error.pointee = errorMessage
            return
        }
        
        let alert = NSAlert()
        alert.messageText = "Hello \(str)"
        alert.informativeText = "Welcome in the service"
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
