//
//  EventMonitor.swift
//  Later
//
//  Created by Peter Zignego on 11/2/15.
//  Copyright © 2016 Launch Software. All rights reserved.
//

import Cocoa

open class EventMonitor {
    fileprivate var monitor: Any?
    fileprivate let mask: NSEventMask
    fileprivate let handler: (NSEvent?) -> ()
    
    public init(mask: NSEventMask, handler: @escaping (NSEvent?) -> ()) {
        self.mask = mask
        self.handler = handler
    }
    
    deinit {
        stop()
    }
    
    open func start() {
        monitor = NSEvent.addGlobalMonitorForEvents(matching: mask, handler: handler)
        (NSApplication.shared().delegate as? AppDelegate)?.registerForNotifications()
    }
    
    open func stop() {
        if monitor != nil {
            NSEvent.removeMonitor(monitor!)
            monitor = nil
        }
        (NSApplication.shared().delegate as? AppDelegate)?.deregisterForNotifications()
    }
}
