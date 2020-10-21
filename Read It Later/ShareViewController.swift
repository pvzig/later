//
//  ShareViewController.swift
//  Read It Later
//
//  Created by Peter Zignego on 11/14/15.
//  Copyright © 2016 Launch Software. All rights reserved.
//

import Cocoa
import LaterKit
import LinkPresentation

class ShareViewController: NSViewController {
    
    override var nibName: NSNib.Name? {
        return "ShareViewController"
    }
    
    override func loadView() {
        super.loadView()
        guard let item = self.extensionContext?.inputItems[0] as? NSExtensionItem, let attachments = item.attachments else {
            finish()
            return
        }
        
        if let provider = attachments.first(where: { $0.canLoadObject(ofClass: NSURL.self) }) {
            provider.loadObject(ofClass: NSURL.self) { (item, error) in
                guard let nsURL = item as? NSURL, let url = nsURL.absoluteURL else {
                    self.finish()
                    return
                }
                DispatchQueue.main.async {
                    let lp = LPMetadataProvider()
                    lp.timeout = 5
                    lp.startFetchingMetadata(for: url) { (metadata, error) in
                        let title = metadata?.title
                        Later.shared.saveURL(url, title: title)
                        Later.shared.saveGroup.notify(queue: .main) {
                            self.finish()
                        }
                    }
                }
            }
        // Failed
        } else {
            self.finish()
        }
    }
    
    private func finish() {
        extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }
    
    deinit {
        finish()
    }
}
