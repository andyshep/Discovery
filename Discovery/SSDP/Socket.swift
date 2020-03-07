//
//  Socket.swift
//  Discovery
//
//  Created by Andrew Shepard on 2/27/20.
//  Copyright © 2020 Andrew Shepard. All rights reserved.
//

import Foundation
import Darwin

struct Socket {

    private let descriptor: Int32
    
    init(descriptor: Int32) {
        self.descriptor = descriptor
    }
    
    init?(domain: SocketDomain, type: SocketType, protocol: SocketProtocol) {
        let result = Darwin.socket(domain.rawValue, type.rawValue, `protocol`.rawValue)
        guard result != -1 else { return nil }
        self.descriptor = result
    }
}

extension Socket {
    func send(message: String, address: String, port: Int) throws {
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
    
    func receive(address: String, port: Int, dataReceived callback: (Result<Data, Error>) -> Void) {
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
                level: .protocolIP,
                name: .addMembership,
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
                return callback(.failure(SocketError.receiveFailed(code: errno)))
            }
            
            // convert buffer into data
            let data = Data(bytes: bufferPtr, count: count)
            callback(.success(data))
        }
    }
    
    private func bind(address: UnsafePointer<sockaddr>, length: socklen_t) throws {
        guard Darwin.bind(descriptor, address, length) == 0 else {
            throw SocketError.bindFailed(code: errno)
        }
    }
    
    func setOption(level: SocketOptionLevel, name: SocketOption, value: UnsafeRawPointer, length: socklen_t) throws {
        guard Darwin.setsockopt(descriptor, level.rawValue, name.rawValue, value, length) == 0 else {
            throw SocketError.setOptionFailed(code: errno)
        }
    }
    
    func close() throws {
        guard Darwin.close(descriptor) == 0 else {
            throw SocketError.closeFailed(code: errno)
        }
    }
    
    func forceClose() {
        guard let _ = try? close() else { return }
    }
    
    // MARK: Private
    
    private func connect(address: UnsafePointer<sockaddr>, length: socklen_t) throws {
        guard Darwin.connect(descriptor, address, length) != -1 else {
            throw SocketError.connectFailed(code: errno)
        }
    }
    
    private func send(buffer: UnsafeBufferPointer<UInt8>, flags: Int32 = 0) throws {
        guard Darwin.send(descriptor, buffer.baseAddress, buffer.count, flags) != -1 else {
            throw SocketError.sendFailed(code: errno)
        }
    }
    
    private func send(buffer: UnsafeRawPointer, flags: Int32 = 0, destination: UnsafePointer<sockaddr>, length: socklen_t) throws {
        let bufferCount = Int(strlen(buffer.assumingMemoryBound(to: Int8.self)) + 1)
        let result = Darwin.sendto(descriptor, buffer, bufferCount, flags, destination, length)
        guard result >= 0 else {
            throw SocketError.sendFailed(code: errno)
        }
    }
}

enum SocketAddressConfig: UInt8 {
    case ipv4
    case ipv6
    
    var rawValue: UInt8 {
        switch self {
        case .ipv4:
            return UInt8(AF_INET)
        case .ipv6:
            return UInt8(AF_INET6)
        }
    }
}

enum SocketDomain: Int32 {
    case local
    case inet
    case inet6
    
    var rawValue: Int32 {
        switch self {
        case .local:
            return PF_LOCAL
        case .inet:
            return PF_INET
        case .inet6:
            return PF_INET
        }
    }
}

enum SocketType: Int32 {
    case stream
    case dgram
    case raw
    
    var rawValue: Int32 {
        switch self {
        case .stream:
            return SOCK_STREAM
        case .dgram:
            return SOCK_DGRAM
        case .raw:
            return SOCK_RAW
        }
    }
}

enum SocketProtocol: Int32 {
    case tcp
    case udp
    
    var rawValue: Int32 {
        switch self {
        case .tcp:
            return IPPROTO_TCP
        case .udp:
            return IPPROTO_UDP
        }
    }
}

enum SocketOption: Int32 {
    case broadcast
    case debug
    case reuseAddress
    case addMembership
    
    var rawValue: Int32 {
        switch self {
        case .broadcast:
            return SO_BROADCAST
        case .debug:
            return SO_DEBUG
        case .reuseAddress:
            return SO_REUSEADDR
        case .addMembership:
            return IP_ADD_MEMBERSHIP
        }
    }
}

enum SocketOptionLevel: Int32 {
    case socket
    case local
    case protocolIP
    
    var rawValue: Int32 {
        switch self {
        case .socket:
            return SOL_SOCKET
        case .local:
            return SOL_LOCAL
        case .protocolIP:
            return IPPROTO_IP
        }
    }
}

enum SocketError: Error, CustomStringConvertible {
    case connectFailed(code: Int32)
    case bindFailed(code: Int32)
    case sendFailed(code: Int32)
    case closeFailed(code: Int32)
    case receiveFailed(code: Int32)
    case invalidAddress(code: Int32)
    case setOptionFailed(code: Int32)
    
    var description: String {
        switch self {
        case .connectFailed(let code),
             .bindFailed(let code),
             .sendFailed(let code),
             .closeFailed(let code),
             .receiveFailed(let code),
             .invalidAddress(let code),
             .setOptionFailed(let code):
            return String(utf8String: strerror(code)) ?? ""
        }
    }
}

struct SocketConfiguration {
    private var address: sockaddr_in
    
    init(address: sockaddr_in) {
        self.address = address
    }
    
    init?(address: String, port: Int) {
        var addr = sockaddr_in()
        addr.sin_family = SocketAddressConfig.ipv4.rawValue
        addr.sin_port = htons(1900)
        
        var addressPtr = address.toUnsafeMutablePointer()
        defer { free(addressPtr) }
        
        Darwin.inet_pton(2, addressPtr, &addr.sin_addr)
        
        self.address = addr
    }
    
    lazy var addressPtr: UnsafeMutablePointer<sockaddr> = {
        return withUnsafeMutablePointer(to: &address) { ptr in
            return ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) { UnsafeMutablePointer($0) }
        }
    }()
    
    static func makeBroadcast(address: String = "239.255.255.250", port: Int = 1900) -> SocketConfiguration {
        var addr = sockaddr_in()
        addr.sin_family = 2 // AF_INET
        addr.sin_port = htons(UInt16(port))
        
        Darwin.inet_pton(2, address.toUnsafeMutablePointer(), &addr.sin_addr)
        
        return SocketConfiguration(address: addr)
    }
    
    static func makeReceive(address: String = "239.255.255.250", port: Int = 1900) -> SocketConfiguration {
        var addr = sockaddr_in()
        addr.sin_family = 2 // AF_INET
        addr.sin_port = htons(1900)
        addr.sin_addr.s_addr = htonl(INADDR_ANY)
        
        Darwin.inet_pton(2, address.toUnsafeMutablePointer(), &addr.sin_addr)
        
        return SocketConfiguration(address: addr)
    }
}

private extension String {
    func toUnsafePointer() -> UnsafePointer<UInt8>? {
        guard let data = data(using: .utf8) else {
            return nil
        }

        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: data.count)
        let stream = OutputStream(toBuffer: buffer, capacity: data.count)
        stream.open()
        defer { stream.close() }
        
        let value = data.withUnsafeBytes { $0.baseAddress?.assumingMemoryBound(to: UInt8.self) }
        guard let val = value else { return nil }
        stream.write(val, maxLength: data.count)

        return UnsafePointer<UInt8>(buffer)
    }

    func toUnsafeMutablePointer() -> UnsafeMutablePointer<Int8>? {
        return strdup(self)
    }
}

private func htons(_ value: UInt16) -> UInt16 {
    // https://gist.github.com/shavit/2706028c142c953adf8b51dc5f9ba2f2
    
    return (value << 8) + (value >> 8)
}

private func htonl(_ value: UInt32) -> UInt32 {
    // https://stackoverflow.com/a/24395014
    
    return CFSwapInt32HostToBig(value)
}
