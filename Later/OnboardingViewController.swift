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
    
    @IBAction func extensionPanelButton(sender: NSButton) {
        NSWorkspace.sharedWorkspace().openFile("/System/Library/PreferencePanes/Extensions.prefPane")
    }
    
    @IBAction func nextButton(sender: NSButton) {
        NSUserDefaults.standardUserDefaults().setBool(true, forKey: "onboardingComplete")
        
        if let app = NSApplication.sharedApplication().delegate as? AppDelegate {
            let vc = ViewController(nibName: "PopoverView", bundle: nil)
            app.popover.contentViewController = vc
        }
    }
    
}