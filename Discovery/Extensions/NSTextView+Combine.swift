//
//  NSTextView+Combine.swift
//  Discovery
//
//  Created by Andrew Shepard on 3/7/20.
//  Copyright © 2020 Andrew Shepard. All rights reserved.
//

import Cocoa
import Combine

extension NSTextView {
    
    typealias LinkPublisher = AnyPublisher<URL, Never>
    
    var clickedLinkPublisher: LinkPublisher {
        return proxy.clickedLinkPublisher
    }
    
    private var proxy: textViewProxy {
        get {
            guard let value = objc_getAssociatedObject(self, &_textViewProxyKey) as? textViewProxy else {
                let proxy = textViewProxy(textView: self)
                objc_setAssociatedObject(self, &_textViewProxyKey, proxy, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                return proxy
            }
            return value
        }
    }
}

private var _textViewProxyKey: UInt8 = 0
private class textViewProxy: NSObject {
    
    var clickedLinkPublisher: AnyPublisher<URL, Never> {
        return _clickedLinkPublisher.eraseToAnyPublisher()
    }
    private let _clickedLinkPublisher = PassthroughSubject<URL, Never>()

    private let textView: NSTextView

    init(textView: NSTextView) {
        self.textView = textView
        super.init()
        
        textView.delegate = self
    }
    
    deinit {
        textView.delegate = nil
    }
}

// MARK: <NSTextViewDelegate>

extension textViewProxy: NSTextViewDelegate {
    func textView(_ textView: NSTextView, clickedOnLink link: Any, at charIndex: Int) -> Bool {
        guard let url = link as? URL else { return false }
        
        _clickedLinkPublisher.send(url)
        
        return true
    }
}

