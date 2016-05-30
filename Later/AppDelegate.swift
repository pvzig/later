//
//  AppDelegate.swift
//  ShareToInstapaper
//
//  Created by Peter Zignego on 10/3/15.
//  Copyright © 2016 Launch Software. All rights reserved.
//

import Cocoa
import AppKit

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!
    
    let statusItem = NSStatusBar.systemStatusBar().statusItemWithLength(19)
    let popover = NSPopover()
    var eventMonitor: EventMonitor?

    func applicationWillFinishLaunching(notification: NSNotification) {
        
    }
    
    func applicationDidFinishLaunching(notification: NSNotification) {
        window.hidesOnDeactivate = true
        window.canHide = true
        NSWorkspace.sharedWorkspace().notificationCenter.addObserver(self, selector: #selector(AppDelegate.closePopover(_:)), name: NSWorkspaceActiveSpaceDidChangeNotification, object: nil)
        if let button = statusItem.button {
            button.image = NSImage(named: "later-menu")
            button.action = #selector(AppDelegate.togglePopover(_:))
        }
        
        if NSUserDefaults.standardUserDefaults().boolForKey("onboardingComplete") == false {
            let vc = OnboardingViewController(nibName: "OnboardingView", bundle: nil)
            popover.contentViewController = vc
        } else {
            let vc = ViewController(nibName: "PopoverView", bundle: nil)
            popover.contentViewController = vc
        }
        eventMonitor = EventMonitor(mask: [NSEventMask.LeftMouseDownMask, NSEventMask.RightMouseDownMask]) {
            [unowned self] event in
            if self.popover.shown {
                self.closePopover(event)
            }
        }
        eventMonitor?.start()
    }
    
    func showPopover(sender: AnyObject?) {
        if let button = statusItem.button {
            popover.showRelativeToRect(button.bounds, ofView: button, preferredEdge: NSRectEdge.MinY)
        }
    }
    
    func closePopover(sender: AnyObject?) {
        popover.performClose(sender)
    }
    
    func togglePopover(sender: AnyObject?) {
        if popover.shown {
            closePopover(sender)
        } else {
            showPopover(sender)
        }
    }

}
