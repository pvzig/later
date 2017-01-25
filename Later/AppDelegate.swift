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
    
    let statusItem = NSStatusBar.system().statusItem(withLength: 19)
    let popover = NSPopover()
    var eventMonitor: EventMonitor?

    func applicationWillFinishLaunching(_ notification: Notification) {}
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        window.hidesOnDeactivate = true
        window.canHide = true

        if let button = statusItem.button {
            button.image = NSImage(named: "later-menu")
            button.action = #selector(AppDelegate.togglePopover(_:))
        }
        
        if UserDefaults.standard.bool(forKey: "onboardingComplete") == false {
            let vc = OnboardingViewController(nibName: "OnboardingView", bundle: nil)
            popover.contentViewController = vc
        } else {
            let vc = ViewController(nibName: "PopoverView", bundle: nil)
            popover.contentViewController = vc
        }
        
        eventMonitor = EventMonitor(mask: [.leftMouseDown, .rightMouseDown]) {[unowned self] event in
            if self.popover.isShown {
                self.closePopover(event)
            }
        }
        eventMonitor?.start()
    }
    
    func showPopover(_ sender: AnyObject?) {
        if let button = statusItem.button {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }
    
    func closePopover(_ sender: AnyObject?) {
        popover.performClose(sender)
    }
    
    func togglePopover(_ sender: AnyObject?) {
        if popover.isShown {
            closePopover(sender)
        } else {
            showPopover(sender)
        }
    }
    
    func registerForNotifications() {
        NSWorkspace.shared().notificationCenter.addObserver(self,
                                                            selector: #selector(AppDelegate.closePopover(_:)),
                                                            name: NSNotification.Name.NSWorkspaceActiveSpaceDidChange,
                                                            object: nil)
    }
    
    func deregisterForNotifications() {
        NSWorkspace.shared().notificationCenter.removeObserver(self)
    }
}
