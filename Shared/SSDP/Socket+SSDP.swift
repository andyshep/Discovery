//
//  SSDP.swift
//  Discovery
//
//  Created by Andrew Shepard on 3/7/20.
//  Copyright © 2020 Andrew Shepard. All rights reserved.
//

import Foundation

extension Socket {
    
    /// Sends a message over the socket
    /// - Parameters:
    ///   - message: The message to send
    ///   - address:The address to send a message over
    ///   - port: The port to send a message over
    func send(message: String, address: String = SSDP.address, port: Int = SSDP.port) throws {
        var config = SocketConfiguration.makeBroadcast(
            address: address,
            port: port
        )
        
        try message.withCString { messagePtr -> Void in
            try send(
                buffer: messagePtr,
                destination: config.addressPtr,
                length: socklen_t(MemoryLayout<sockaddr>.size)
            )
        }
    }
    
    func sendBroadcast() throws {
        try send(message: SSDP.payload)
    }
    
    func receive(address: String = SSDP.address,
                 port: Int = SSDP.port,
                 dataReceived callback: (Result<Data, Swift.Error>) -> Void) {
        var config = SocketConfiguration.makeReceive(
            address: address,
            port: port
        )
        
        do {
            try bind(
                address: config.addressPtr,
                length: socklen_t(MemoryLayout<sockaddr>.size)
            )
        } catch {
            callback(.failure(error))
        }
        
        var mreq = ip_mreq()
        mreq.imr_multiaddr.s_addr = inet_addr(address)
        mreq.imr_interface.s_addr = htonl(INADDR_ANY)
        
        do {
            try setOption(
                name: .addMembership,
                level: .protocolIP,
                value: &mreq,
                length: socklen_t(MemoryLayout<ip_mreq>.size)
            )
        } catch {
            callback(.failure(error))
        }
        
        let count = 512
        let bufferPtr = UnsafeMutableRawPointer.allocate(
            byteCount: count, alignment:
            MemoryLayout<Int8>.alignment
        )
        defer { free(bufferPtr) }
        
        while true {
            bufferPtr.initializeMemory(as: Int8.self, repeating: 0, count: count)
            var addrlen = UInt32(MemoryLayout<sockaddr_in>.size)
            
            // try to receive data from socket
            guard Darwin.recvfrom(descriptor, bufferPtr, count, 0, config.addressPtr, &addrlen) > 0 else {
                return callback(.failure(Error.receiveFailed(code: errno)))
            }
            
            // convert buffer into data
            let data = Data(bytes: bufferPtr, count: count)
            callback(.success(data))
        }
    }
}

extension SocketConfiguration {
    static func makeBroadcast(address: String = SSDP.address, port: Int = SSDP.port) -> SocketConfiguration {
        var addr = sockaddr_in()
        addr.sin_family = Socket.AddressConfig.ipv4.rawValue
        addr.sin_port = htons(UInt16(port))
        
        Darwin.inet_pton(2, address.toUnsafeMutablePointer(), &addr.sin_addr)
        
        return SocketConfiguration(address: addr)
    }
    
    static func makeReceive(address: String = SSDP.address, port: Int = SSDP.port) -> SocketConfiguration {
        var addr = sockaddr_in()
        addr.sin_family = Socket.AddressConfig.ipv4.rawValue
        addr.sin_port = htons(UInt16(port))
        addr.sin_addr.s_addr = htonl(INADDR_ANY)
        
        Darwin.inet_pton(2, address.toUnsafeMutablePointer(), &addr.sin_addr)
        
        return SocketConfiguration(address: addr)
    }
}

internal struct SSDP {
    
    static var payload: String {
        return """
            M-SEARCH * HTTP/1.1\r\n
            HOST: \(address):\(port)\r\n
            MAN: \"ssdp:discover\"\r\n
            ST: ssdp:all\r\n
            MX: 1\r\n\r\n
        """
    }
    
    static var address: String {
        return "239.255.255.250"
    }
    
    static var port: Int {
        return 1900
    }
}
