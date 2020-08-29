//
//  SSDPManager.swift
//  Discovery
//
//  Created by Andrew Shepard on 2/27/20.
//  Copyright © 2020 Andrew Shepard. All rights reserved.
//

import Foundation
import Combine

final class SSDPManager {
    
    private enum Error: Swift.Error {
        case retainFailed
    }
    
    /// Emits with new SSDP data received from the socket
    var listenerSocketSubject: AnyPublisher<Result<Data, Swift.Error>, Never> {
        return _listenerSocketSubject
            .handleEvents(
                receiveSubscription: { [unowned self] _ in
                    self.startListening()
                }
            )
            .print()
            .eraseToAnyPublisher()
    }
    private let _listenerSocketSubject = PassthroughSubject<Result<Data, Swift.Error>, Never>()
    
    /// To be triggered when an SSDP broadcast should be sent
    var broadcastEventTrigger: AnySubscriber<Void, Never> {
        return AnySubscriber(_broadcastEventTrigger)
    }
    private let _broadcastEventTrigger = PassthroughSubject<Void, Never>()
    
    private lazy var startListening: () -> Void = {
        listenerQueue.async { [weak self] in
            self?.listenerSocket.receive { result in
                DispatchQueue.main.async {
                    self?._listenerSocketSubject.send(result)
                }
            }
        }
        return { }
    }()
    
    private var cancellables: Set<AnyCancellable> = Set()
    
    private var broadcastSocket: Socket
    private var listenerSocket: Socket
    
    private let broadcastQueue = DispatchQueue.init(label: "broadcast-queue")
    private let listenerQueue = DispatchQueue.init(label: "listening-queue")
    
    init?() {
        guard let broadcast = try? Socket(domain: .inet, type: .dgram, protocol: .udp) else { return nil }
        guard let _ = try? configureAsBroadcast(socket: broadcast) else { return nil }
        
        self.broadcastSocket = broadcast
        
        guard let listener = try? Socket(domain: .inet, type: .dgram, protocol: .udp) else { return nil }
        guard let _ = try? configureAsListener(socket: listener) else { return nil }
        
        self.listenerSocket = listener
        
        _broadcastEventTrigger
            .eraseToAnyPublisher()
            .flatMapLatest { [unowned self] _ in
                self.sendBroadcast().replaceError(with: ())
            }
            .subscribe(andStoreIn: &cancellables)
    }
    
    deinit {
        broadcastSocket.forceClose()
        listenerSocket.forceClose()
    }
    
    private func sendBroadcast() -> Future<Void, Swift.Error> {
        return Future<Void, Swift.Error> { [weak self] promise in
            guard let this = self else {
                return promise(.failure(Error.retainFailed))
            }
            
            this.broadcastQueue.async {
                do {
                    try this.broadcastSocket.sendBroadcast()
                    
                    DispatchQueue.main.async {
                        promise(.success(()))
                    }
                } catch {
                    DispatchQueue.main.async {
                        promise(.failure(error))
                    }
                }
            }
        }
    }
}

private func configureAsBroadcast(socket: Socket) throws {
    var broadcastEnable: UInt32 = 1
    try socket.setOption(
        name: .broadcast,
        level: .socket,
        value: &broadcastEnable,
        length: socklen_t(MemoryLayout<socklen_t>.size)
    )
}

private func configureAsListener(socket: Socket) throws {
    var reuseAddressEnable: UInt32 = 1
    try socket.setOption(
        name: .reuseAddress,
        level: .socket,
        value: &reuseAddressEnable,
        length: socklen_t(MemoryLayout<socklen_t>.size)
    )
}
