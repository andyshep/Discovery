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
            let expiry = cacheControlString.expiryDate
        else { return nil }
            
        self.location = locationURL
        self.server = server
        self.uniqueServiceName = uniqueServiceName
        self.cacheControl = expiry
    }
}

extension Data {
    var service: SSDPService? {
        guard
            let discovery = String(data: self, encoding: .utf8),
            let ssdpService = SSDPService(dictionary: discovery.serviceInfo)
        else { return nil }
        
        return ssdpService
    }
}

private extension String {
    var serviceInfo: [String: String] {
        return split(separator: "\r\n")
            .reduce(into: [String: String]()) { (results, element) in
                let keyValuePair = element.split(separator: ":", maxSplits: 1)
                
                guard keyValuePair.count == 2 else { return }

                let key = String(keyValuePair[0]).uppercased()
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                let value = String(keyValuePair[1])
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                
                results[key] = value
            }
    }
    
    var expiryDate: Date? {
        guard let last = split(separator: "=").last else { return nil }
        guard let value = Double(String(last)) else { return nil }
        
        return Date().advanced(by: value)
    }
}
