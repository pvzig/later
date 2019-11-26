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

    let statusItem = NSStatusBar.system.statusItem(withLength: 19)
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupService()
        setupMenu()
        // Migration for 1.2.0
        Later.shared.migrate()
        
        if !User.isOnboardingComplete {
            let windowController = NSWindowController(window: window)
            windowController.showWindow(self)
        }
    }
    
    private func setupService() {
        NSApplication.shared.servicesProvider = ReadLaterService()
        NSUpdateDynamicServices()
    }
    
    private func setupMenu() {
        if let button = statusItem.button {
            button.image = NSImage(named: "later-menu")
            let menu = NSMenu()
            let setup = NSMenuItem(title: "Setup Accounts", action: .showWindow, keyEquivalent: "a")
            let ext = NSMenuItem(title: "Add Extension", action: .openExtension, keyEquivalent: "e")
            let support = NSMenuItem(title: "Email Support", action: .emailSupport, keyEquivalent: "s")
            let reset = NSMenuItem(title: "Reset Accounts", action: .resetAccounts, keyEquivalent: "")
            let about = NSMenuItem(title: "About", action: .showAbout, keyEquivalent: "")
            let quit = NSMenuItem(title: "Quit", action: .quit, keyEquivalent: "q")
            menu.addItem(setup)
            menu.addItem(ext)
            menu.addItem(support)
            menu.addItem(about)
            menu.addItem(.separator())
            menu.addItem(reset)
            menu.addItem(.separator())
            menu.addItem(quit)
            statusItem.menu = menu
        }
    }
    
    // MARK: - Menu actions
    
    @objc
    func showWindow() {
        let windowController = NSWindowController(window: window)
        windowController.showWindow(self)
    }
    
    @objc
    func openExtension() {
        NSWorkspace.shared.openFile("/System/Library/PreferencePanes/Extensions.prefPane")
    }
    
    @objc
    func showAbout() {
        let aboutWindow = NSWindowController(windowNibName: "About")
        aboutWindow.showWindow(self)
    }
    
    @objc
    func emailSupport() {
        let url = URL(string: "mailto:peter@launchsoft.co?subject=Later%20Support")!
        NSWorkspace.shared.open(url)
    }
    
    @objc
    func resetAccounts() {
        let alert = NSAlert()
        alert.messageText = "Reset All Accounts?"
        alert.informativeText = "Resetting your accounts will log out of all services and clear Later's application data."
        alert.addButton(withTitle: "Reset All Accounts")
        alert.addButton(withTitle: "Cancel")
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            Later.shared.reset()
            NotificationCenter.default.post(name: .updateUI, object: nil)
        }
    }
    
    @objc
    func quit() {
        NSApplication.shared.terminate(self)
    }
}

extension Selector {
    static let showWindow = #selector(AppDelegate.showWindow)
    static let openExtension = #selector(AppDelegate.openExtension)
    static let showAbout = #selector(AppDelegate.showAbout)
    static let emailSupport = #selector(AppDelegate.emailSupport)
    static let resetAccounts = #selector(AppDelegate.resetAccounts)
    static let quit = #selector(AppDelegate.quit)
}

extension Notification.Name {
    static let updateUI = Notification.Name("updateLaterUI")
}
