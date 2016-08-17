//
//  ObjectId.swift
//  BSON
//
//  Created by Joannis Orlandos on 23/01/16.
//  Copyright © 2016 Robbert Brandsma. All rights reserved.
//

import Foundation

#if os(Linux)
    import Glibc
#endif

/// 12-byte unique ID
///
/// Defined as: `UNIX epoch time` + `machine identifier` + `process ID` + `random increment`
public struct ObjectId {
    public typealias Raw = (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8)
    
    #if os(Linux)
    private static var random: UInt8 = Int32(rand()).bytes[0]
    #else
    private static var random: UInt8 = UInt8(arc4random_uniform(255))
    #endif
    
    private static var counter: Int16 = 0
    
    public var storage: Raw {
        get {
            return (_storage[0], _storage[1], _storage[2], _storage[3], _storage[4], _storage[5], _storage[6], _storage[7], _storage[8], _storage[9], _storage[10], _storage[11])
        }
        set {
            self._storage = [newValue.0, newValue.1, newValue.2, newValue.3, newValue.4, newValue.5, newValue.6, newValue.7, newValue.8, newValue.9, newValue.10, newValue.11]
        }
    }
    
    internal var _storage: [UInt8]
    
    /// Generate a new random ObjectId.
    public init() {
        let currentTime = Date()
        
        var data = [UInt8]()
        
        // Take the current UNIX epoch as Int32 and take it's bytes
        data += Int32(currentTime.timeIntervalSince1970).bytes
        
        #if os(Linux)
            let processInfo = ProcessInfo.processInfo()
        #else
            let processInfo = ProcessInfo.processInfo
        #endif
        
        // Take the machine identifier
        data += Array(processInfo.hostName.hash.bytes[0...2])
        
        // Take the process identifier as 2 bytes
        data += Array(processInfo.processIdentifier.bytes[0...1])
        
        // Take a random number
        data += [ObjectId.random]
        
        if ObjectId.counter == Int16.max - 1 {
            ObjectId.counter = Int16.min
        }
        
        // And add a counter as 2 bytes and increment it
        data += ObjectId.counter.bytes
        ObjectId.counter += 1
        
        self._storage = data
    }
    
    /// Initialize a new ObjectId from given Hexadecimal string, such as "0123456789abcdef01234567".
    ///
    /// **Note that this string should always be a valid hexadecimal string of 24 characters.**
    ///
    /// Throws errors in case of an invalid string (e.g. wrong length)
    public init(_ hexString: String) throws {
        guard hexString.characters.count == 24 else {
            throw DeserializationError.ParseError
        }
        
        var data = [UInt8]()
        
        var gen = hexString.characters.makeIterator()
        while let c1 = gen.next(), let c2 = gen.next() {
            let s = String([c1, c2])
            
            guard let d = UInt8(s, radix: 16) else {
                break
            }
            
            data.append(d)
        }
        
        guard data.count == 12 else {
            throw DeserializationError.ParseError
        }
        
        self._storage = data
    }
    
    /// Initializes this ObjectId with a tuple of 12 bytes
    public init(raw storage: Raw) {
        self._storage = [storage.0, storage.1, storage.2, storage.3, storage.4, storage.5, storage.6, storage.7, storage.8, storage.9, storage.10, storage.11]
    }
    
    /// Initializes ObjectId with an array of bytes
    ///
    /// Throws when there are not exactly 12 bytes provided
    public init(bytes data: [UInt8]) throws {
        guard data.count == 12 else {
            throw DeserializationError.InvalidElementSize
        }

        self._storage = data
    }
    
    /// The 12 bytes represented as 24-character hex-string
    public var hexString: String {
        return _storage.map {
            var s = String($0, radix: 16, uppercase: false)
            while s.characters.count < 2 {
                s = "0" + s
            }
            return s
            }.joined(separator: "")
    }
}
