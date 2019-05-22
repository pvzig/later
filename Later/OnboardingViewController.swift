//
//  OnboardingViewController.swift
//  Later
//
//  Created by Peter Zignego on 2/23/16.
//  Copyright © 2016 Launch Software. All rights reserved.
//

import Cocoa
import LaterKit

class OnboardingViewController: NSViewController {
    
    @IBAction func extensionPanelButton(_ sender: NSButton) {
        NSWorkspace.shared.openFile("/System/Library/PreferencePanes/Extensions.prefPane")
        User.setOnboardingComplete()
        AppDelegate.sharedDelegate.popover.contentViewController = PopoverViewController(nibName: "PopoverView", bundle: nil)
        AppDelegate.sharedDelegate.closePopover(self)
    }
}
