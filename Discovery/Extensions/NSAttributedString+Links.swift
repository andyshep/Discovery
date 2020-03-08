//
//  NSAttributedString+Links.swift
//  Discovery
//
//  Created by Andrew Shepard on 3/7/20.
//  Copyright © 2020 Andrew Shepard. All rights reserved.
//

import Cocoa

extension NSMutableAttributedString {
    func withLinkAttributesAdded() {
        guard
            let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        else { return }
        
        let matches = detector.matches(
            in: string,
            options: [],
            range: NSRange(location: 0, length: string.utf16.count)
        )

        for match in matches {
            guard let range = Range(match.range, in: string) else { continue }
            
            let urlString = String(string[range])
            
            guard urlString.starts(with: "http://") else { continue }
            guard let url = URL(string: urlString) else { continue }
            
            addAttribute(.link, value: url, range: NSRange(range, in: string))
        }
        
        addAttribute(.font, value: NSFont.monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .medium), range: NSRange(location: 0, length: string.utf16.count))
    }
}
