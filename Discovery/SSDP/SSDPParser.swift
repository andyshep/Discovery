//
//  SSDPParser.swift
//  Discovery
//
//  Created by Andrew Shepard on 3/1/20.
//  Copyright © 2020 Andrew Shepard. All rights reserved.
//

import Foundation

struct SSDPService {
    let cacheControl: Date
    let location: URL
    let server: String
    let uniqueServiceName: String
    
    private enum SSDPServiceResponseKey: String {
        case cacheControl = "CACHE-CONTROL"
        case location = "LOCATION"
        case server = "SERVER"
        case uniqueServiceName = "USN"
    }
    
    init?(dictionary: [String: String]) {
        guard
            let cacheControlString = dictionary[SSDPServiceResponseKey.cacheControl.rawValue],
            let location = dictionary[SSDPServiceResponseKey.location.rawValue],
            let server = dictionary[SSDPServiceResponseKey.server.rawValue],
            let uniqueServiceName = dictionary[SSDPServiceResponseKey.uniqueServiceName.rawValue]
        else { return nil }
        
        guard
            let locationURL = URL(string: location),
            let expiry = SSDPService.expiryDate(fromCacheControl: cacheControlString)
        else { return nil }
            
        self.location = locationURL
        self.server = server
        self.uniqueServiceName = uniqueServiceName
        self.cacheControl = expiry
    }
    
    private static func expiryDate(fromCacheControl string: String) -> Date? {
        guard let last = string.split(separator: "=").last else { return nil }
        guard let value = Double(String(last)) else { return nil }
        
        return Date().advanced(by: value)
    }
}

final class SSDPServiceParser {

    static func parse(_ data: Data) -> SSDPService? {
        guard
            let discovery = String(data: data, encoding: .utf8),
            let ssdpService = SSDPService(dictionary: parseIntoDictionary(discovery))
        else { return nil }
        
        return ssdpService
    }
    
    // MARK: Private

    private static func parseIntoDictionary(_ response: String) -> [String: String] {
        var elements: [String: String] = [:]
        for element in response.split(separator: "\r\n") {
            let keyValuePair = element.split(separator: ":", maxSplits: 1)
            guard keyValuePair.count == 2 else { continue }

            let key = String(keyValuePair[0]).uppercased()
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let value = String(keyValuePair[1])
                .trimmingCharacters(in: .whitespacesAndNewlines)

            elements[key] = value
        }

        return elements
    }
}
