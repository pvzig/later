//
//  OnboardingViewController.swift
//  Later
//
//  Created by Peter Zignego on 2/23/16.
//  Copyright © 2016 Launch Software. All rights reserved.
//

import LaterKit

class OnboardingViewController: NSViewController {
    
    @IBAction func extensionPanelButton(_ sender: NSButton) {
        NSWorkspace.shared.openFile("/System/Library/PreferencePanes/Extensions.prefPane")
        User.isOnboardingComplete = true
        view.window?.close()
    }
}
