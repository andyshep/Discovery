//
//  AppEnvironment.swift
//  Discovery
//
//  Created by Andrew Shepard on 8/7/20.
//

import Foundation
import Combine

struct AppEnvironment {
    private let ssdpManager: SSDPManager
    
    init(ssdpManager: SSDPManager = SSDPManager()!) {
        self.ssdpManager = ssdpManager
    }
}

extension AppEnvironment {
    /// Returns a publisher to emits a collection of discovered SSDP services
    func discoveredServicesPublisher() -> AnyPublisher<[SSDPServiceWrapper], Error> {
        var results: [SSDPServiceWrapper] = []
        
        return ssdpManager.listenerSocketSubject
            .tryMap { result -> [SSDPServiceWrapper] in
                switch result {
                case .success(let data):
                    guard let service = SSDPServiceParser.parse(data) else {
                        print("could not create service from \(data.count) bytes of data")
                        return results
                    }
                    
                    guard let payload = String(data: data, encoding: .utf8) else {
                        print("could not decode utf8 data from \(data.count) bytes of data")
                        return results
                    }
                    
                    let wrapper = SSDPServiceWrapper(service: service, payload: payload)
                    if !results.contains(where: { $0 == wrapper }) {
                        results.append(wrapper)
                    }
                    
                    return results
                case .failure(let error):
                    throw error
                }
            }
            .eraseToAnyPublisher()
    }
}

struct SSDPServiceWrapper: Identifiable, Equatable, Hashable {
    var id: UUID = UUID()
    
    let service: SSDPService
    let payload: String
    
    static func ==(lhs: SSDPServiceWrapper, rhs: SSDPServiceWrapper) -> Bool {
        return lhs.service.uniqueServiceName == rhs.service.uniqueServiceName
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(payload)
    }
}
