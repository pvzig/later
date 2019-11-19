//
//  AppDelegate.swift
//  ShareToInstapaper
//
//  Created by Peter Zignego on 10/3/15.
//  Copyright © 2016 Launch Software. All rights reserved.
//

import LaterKit

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!

    static var sharedDelegate: AppDelegate {
        return NSApplication.shared.delegate as! AppDelegate
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Service
        NSApplication.shared.servicesProvider = ReadLaterService()
        NSUpdateDynamicServices()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}
