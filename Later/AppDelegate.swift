//
//  AppDelegate.swift
//  ShareToInstapaper
//
//  Created by Peter Zignego on 10/3/15.
//  Copyright © 2016 Launch Software. All rights reserved.
//

import Cocoa
import AppKit
import LaterKit

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!
    
    let statusItem = NSStatusBar.system.statusItem(withLength: 19)
    let popover = NSPopover()
    var eventMonitor: EventMonitor?

    func applicationDidFinishLaunching(_ notification: Notification) {
        window.hidesOnDeactivate = true
        window.canHide = true

        if let button = statusItem.button {
            button.image = NSImage(named: NSImage.Name(rawValue: "later-menu"))
            button.action = .togglePopover
        }
        
        if !User.onboardingComplete {
            popover.contentViewController = OnboardingViewController(nibName: NSNib.Name(rawValue: "OnboardingView"), bundle: nil)
        } else {
            popover.contentViewController = PopoverViewController(nibName: NSNib.Name(rawValue: "PopoverView"), bundle: nil)
        }

        // Service
        NSApplication.shared.servicesProvider = ReadLaterService()
        NSUpdateDynamicServices()

        // Monitor events for dismissing the popover
        eventMonitor = EventMonitor(mask: [.leftMouseDown, .rightMouseDown]) { [unowned self] event in
            if self.popover.isShown {
                self.closePopover(event)
            }
        }
        eventMonitor?.start()
    }

    func registerForNotifications() {
        NSWorkspace.shared.notificationCenter.addObserver(self,
                                                            selector: .closePopover,
                                                            name: NSWorkspace.activeSpaceDidChangeNotification,
                                                            object: nil)
    }

    func deregisterForNotifications() {
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }

    private func showPopover(_ sender: AnyObject?) {
        if let button = statusItem.button {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }

    @objc func closePopover(_ sender: AnyObject?) {
        popover.performClose(sender)
    }

    @objc func togglePopover(_ sender: AnyObject?) {
        if popover.isShown {
            closePopover(sender)
        } else {
            showPopover(sender)
        }
    }
}

private extension Selector {
    static let togglePopover = #selector(AppDelegate.togglePopover(_:))
    static let closePopover = #selector(AppDelegate.closePopover(_:))
}
