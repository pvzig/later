//
//  EventMonitor.swift
//  Later
//
//  Created by Peter Zignego on 11/2/15.
//  Copyright © 2016 Launch Software. All rights reserved.
//

import Cocoa

class EventMonitor {
    private var monitor: Any?
    private let mask: NSEvent.EventTypeMask
    private let handler: (NSEvent?) -> ()

    init(mask: NSEvent.EventTypeMask, handler: @escaping (NSEvent?) -> ()) {
        self.mask = mask
        self.handler = handler
    }
    
    deinit {
        stop()
    }

    func start() {
        monitor = NSEvent.addGlobalMonitorForEvents(matching: mask, handler: handler)
        (NSApplication.shared.delegate as? AppDelegate)?.registerForNotifications()
    }

    func stop() {
        if monitor != nil {
            NSEvent.removeMonitor(monitor!)
            monitor = nil
        }
        (NSApplication.shared.delegate as? AppDelegate)?.deregisterForNotifications()
    }
}
