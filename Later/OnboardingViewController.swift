//
//  OnboardingViewController.swift
//  Later
//
//  Created by Peter Zignego on 2/23/16.
//  Copyright © 2016 Launch Software. All rights reserved.
//

import Cocoa

class OnboardingViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func extensionPanelButton(_ sender: NSButton) {
        NSWorkspace.shared().openFile("/System/Library/PreferencePanes/Extensions.prefPane")
        UserDefaults.standard.set(true, forKey: "onboardingComplete")
        if let delegate = NSApplication.shared().delegate as? AppDelegate  {
            delegate.popover.contentViewController = ViewController(nibName: "PopoverView", bundle: nil)
            delegate.closePopover(self)
        }
    }

}
