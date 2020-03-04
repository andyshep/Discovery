//
//  DetailViewController.swift
//  Discovery
//
//  Created by Andrew Shepard on 3/1/20.
//  Copyright © 2020 Andrew Shepard. All rights reserved.
//

import Cocoa

class DetailViewController: NSViewController {
    
    @IBOutlet private weak var textView: NSTextView!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    override var representedObject: Any? {
        didSet {
            guard let payload = representedObject as? String else { return }
            textView.string = payload
        }
    }
}
