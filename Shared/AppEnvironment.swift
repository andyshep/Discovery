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
        return ssdpManager.listenerSocketSubject
            .tryCompactMap { result -> SSDPServiceWrapper? in
                switch result {
                case .success(let data):
                    guard let service = data.service else {
                        print("could not create service from \(data.count) bytes of data")
                        return nil
                    }
                    
                    guard let payload = String(data: data, encoding: .utf8) else {
                        print("could not decode utf8 data from \(data.count) bytes of data")
                        return nil
                    }
                    
                    return SSDPServiceWrapper(service: service, payload: payload)
                case .failure(let error):
                    throw error
                }
            }
            .scan([SSDPServiceWrapper](), { (results, service) -> [SSDPServiceWrapper] in
                guard !results.contains(where: { $0 == service }) else { return results }
                return results + [service]
            })
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
