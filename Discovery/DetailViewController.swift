//
//  DetailViewController.swift
//  Discovery
//
//  Created by Andrew Shepard on 3/1/20.
//  Copyright © 2020 Andrew Shepard. All rights reserved.
//

import Cocoa
import Combine

class DetailViewController: NSViewController {
    
    @IBOutlet private weak var textView: NSTextView!
    
    private var cancellables: [AnyCancellable] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        textView.clickedLinkPublisher
            .sink { (url) in
                NSWorkspace.shared.open(url)
            }
            .store(in: &cancellables)
    }
    
    deinit {
        cancellables.forEach { $0.cancel() }
    }
    
    override var representedObject: Any? {
        didSet {
            guard let payload = representedObject as? String else { return }
            
            let string = NSMutableAttributedString(string: payload)
            string.withLinkAttributesAdded()
            
            textView.textStorage?.append(string)
        }
    }
}
