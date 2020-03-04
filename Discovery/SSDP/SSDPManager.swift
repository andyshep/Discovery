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
    
    private enum SSDPManagerError: Error {
        case retainFailed
    }
    
    private var broadcastPayload: String {
        return "M-SEARCH * HTTP/1.1\r\nHOST:\(broadcastAddress):1900\r\nMAN:\"ssdp:discover\"\r\nST:ssdp:all\r\nMX:1\r\n\r\n"
    }
    
    private var broadcastAddress: String {
        return "239.255.255.250"
    }
    
    private var broadcastSocket: Socket
    private var listenerSocket: Socket
    
    private let broadcastQueue = DispatchQueue.init(label: "broadcast-queue")
    private let listenerQueue = DispatchQueue.init(label: "listening-queue")
    
    var listenerSocketSubject: AnyPublisher<Result<Data, Error>, Never> {
        return _listenerSocketSubject.eraseToAnyPublisher()
    }
    
    private let _listenerSocketSubject = PassthroughSubject<Result<Data, Error>, Never>()
    
    init?() {
        guard let broadcast = Socket(domain: .inet, type: .dgram, protocol: .udp) else { return nil }
        guard let _ = try? configureAsBroadcast(socket: broadcast) else { return nil }
        
        self.broadcastSocket = broadcast
        
        guard let listener = Socket(domain: .inet, type: .dgram, protocol: .udp) else { return nil }
        guard let _ = try? configureAsListener(socket: listener) else { return nil }
        
        self.listenerSocket = listener
    }
    
    deinit {
        broadcastSocket.forceClose()
        listenerSocket.forceClose()
    }
    
    func sendBroadcast() -> Future<Void, Error> {
        return Future<Void, Error> { [weak self] promise in
            guard let this = self else {
                return promise(.failure(SSDPManagerError.retainFailed))
            }
            
            this.broadcastQueue.async {
                do {
                    try this.broadcastSocket.send(
                        message: this.broadcastPayload,
                        address: this.broadcastAddress,
                        port: 1900
                    )
                    
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
    
    func startListening() {
        listenerQueue.async { [weak self] in
            guard let this = self else { return }
            self?.listenerSocket.receive(address: this.broadcastAddress, port: 1900) { result in
                DispatchQueue.main.async {
                    self?._listenerSocketSubject.send(result)
                }
            }
        }
    }
}

private func configureAsBroadcast(socket: Socket) throws {
    var broadcastEnable: UInt32 = 1
    try socket.setOption(
        level: .socket,
        name: .broadcast,
        value: &broadcastEnable,
        length: socklen_t(MemoryLayout<socklen_t>.size)
    )
}

private func configureAsListener(socket: Socket) throws {
    var reuseAddressEnable: UInt32 = 1
    try socket.setOption(
        level: .socket,
        name: .reuseAddress,
        value: &reuseAddressEnable,
        length: socklen_t(MemoryLayout<socklen_t>.size)
    )
}
