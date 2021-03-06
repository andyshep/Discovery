//
//  Socket.swift
//  Discovery
//
//  Created by Andrew Shepard on 2/27/20.
//  Copyright © 2020 Andrew Shepard. All rights reserved.
//

import Foundation
import Darwin.POSIX.stdio
import Darwin.POSIX.sys.socket

struct Socket {

    internal let descriptor: Int32
    
    init(descriptor: Int32) {
        self.descriptor = descriptor
    }
    
    init(domain: Domain, type: `Type`, protocol: `Protocol`) throws {
        let result = Darwin.socket(domain.rawValue, type.rawValue, `protocol`.rawValue)
        guard result != -1 else { throw Error.couldNotOpen(code: result) }
        self.descriptor = result
    }
}

extension Socket {
    
    // MARK: Public
    
    func setOption(name: Option, level: Option.Level, value: UnsafeRawPointer, length: socklen_t) throws {
        guard Darwin.setsockopt(descriptor, level.rawValue, name.rawValue, value, length) == 0 else {
            throw Error.setOptionFailed(code: errno)
        }
    }
    
    func close() throws {
        guard Darwin.close(descriptor) == 0 else {
            throw Error.closeFailed(code: errno)
        }
    }
    
    func forceClose() {
        guard let _ = try? close() else { return }
    }
    
    // MARK: Internal
    
    internal func bind(address: UnsafePointer<sockaddr>, length: socklen_t) throws {
        guard Darwin.bind(descriptor, address, length) == 0 else {
            throw Error.bindFailed(code: errno)
        }
    }
    
    internal func connect(address: UnsafePointer<sockaddr>, length: socklen_t) throws {
        guard Darwin.connect(descriptor, address, length) != -1 else {
            throw Error.connectFailed(code: errno)
        }
    }
    
    internal func send(buffer: UnsafeBufferPointer<UInt8>, flags: Int32 = 0) throws {
        guard Darwin.send(descriptor, buffer.baseAddress, buffer.count, flags) != -1 else {
            throw Error.sendFailed(code: errno)
        }
    }
    
    internal func send(buffer: UnsafeRawPointer, flags: Int32 = 0, destination: UnsafePointer<sockaddr>, length: socklen_t) throws {
        let bufferCount = Int(strlen(buffer.assumingMemoryBound(to: Int8.self)) + 1)
        let result = Darwin.sendto(descriptor, buffer, bufferCount, flags, destination, length)
        guard result >= 0 else {
            throw Error.sendFailed(code: errno)
        }
    }
}

extension Socket {
    
    internal enum Error: Swift.Error, CustomStringConvertible {
        case couldNotOpen(code: Int32)
        case connectFailed(code: Int32)
        case bindFailed(code: Int32)
        case sendFailed(code: Int32)
        case closeFailed(code: Int32)
        case receiveFailed(code: Int32)
        case invalidAddress(code: Int32)
        case setOptionFailed(code: Int32)
        
        var description: String {
            switch self {
            case .couldNotOpen(let code),
                 .connectFailed(let code),
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
    
    enum `Protocol`: Int32 {
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
    
    enum AddressConfig: UInt8 {
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
    
    enum Domain: Int32 {
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
    
    enum `Type`: Int32 {
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
    
    enum Option: Int32 {
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
        
        enum Level: Int32 {
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
    }
}

struct SocketConfiguration {
    private var address: sockaddr_in
    
    init(address: sockaddr_in) {
        self.address = address
    }
    
    init?(address: String, port: Int) {
        var addr = sockaddr_in()
        addr.sin_family = Socket.AddressConfig.ipv4.rawValue
        addr.sin_port = htons(UInt16(port))
        
        let addressPtr = address.toUnsafeMutablePointer()
        defer { free(addressPtr) }
        
        Darwin.inet_pton(2, addressPtr, &addr.sin_addr)
        
        self.address = addr
    }
    
    lazy var addressPtr: UnsafeMutablePointer<sockaddr> = {
        return withUnsafeMutablePointer(to: &address) { ptr in
            return ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) { UnsafeMutablePointer($0) }
        }
    }()
}

internal extension String {
    func toUnsafePointer() -> UnsafePointer<UInt8>? {
        guard let data = data(using: .utf8) else { return nil }

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

internal func htons(_ value: UInt16) -> UInt16 {
    // https://gist.github.com/shavit/2706028c142c953adf8b51dc5f9ba2f2
    
    return (value << 8) + (value >> 8)
}

internal func htonl(_ value: UInt32) -> UInt32 {
    // https://stackoverflow.com/a/24395014
    
    return CFSwapInt32HostToBig(value)
}
