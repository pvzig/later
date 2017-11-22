//
//  ShareViewController.swift
//  Read It Later
//
//  Created by Peter Zignego on 11/14/15.
//  Copyright © 2016 Launch Software. All rights reserved.
//

import Cocoa
import LaterKit

class ShareViewController: NSViewController {
    
    override var nibName: NSNib.Name? {
        return NSNib.Name(rawValue: "ShareViewController")
    }
    
    override func loadView() {
        super.loadView()
        guard
            let item = self.extensionContext?.inputItems[0] as? NSExtensionItem,
            let attachments = item.attachments as? [NSItemProvider]
        else {
            finish()
            return
        }
        for provider in attachments {
            if provider.hasItemConformingToTypeIdentifier(kUTTypePropertyList as String) {
                provider.loadItem(forTypeIdentifier: kUTTypePropertyList as String, options: nil, completionHandler: { (item, error) in
                    let dict = item as? [String: Any]
                    let info = dict?[NSExtensionJavaScriptPreprocessingResultsKey] as? [String: Any]
                    let title = info?["title"] as? String
                    if let urlString = info?["URL"] as? String, let url = URL(string: urlString) {
                        Later.shared.saveURL(url, title: title)
                    }
                    Later.shared.saveGroup.notify(queue: .main) {
                        self.finish()
                    }
                })
            }
        }
    }
    
    private func finish() {
        extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }
    
    deinit {
        finish()
    }
}
