//
//  ObjectId.swift
//  BSON
//
//  Created by Joannis Orlandos on 23/01/16.
//  Copyright © 2016 Robbert Brandsma. All rights reserved.
//

import Foundation
import Dispatch

#if os(Linux)
    import Glibc
#endif

/// 12-byte unique ID
///
/// Defined as: `UNIX epoch time` + `machine identifier` + `process ID` + `random increment`
public struct ObjectId {
    public typealias Raw = (Byte, Byte, Byte, Byte, Byte, Byte, Byte, Byte, Byte, Byte, Byte, Byte)
    
    #if os(Linux)
    private static var random: Int32 = {
        srand(UInt32(time(nil)))
        return rand()
    }()
    private static var counter: Int32 = {
        srand(UInt32(time(nil)))
        return rand()
    }()
    #else
    private static var random = arc4random_uniform(UInt32.max)
    private static var counter = arc4random_uniform(UInt32.max)
    #endif
    
    /// This ObjectId as 12-byte tuple
    public var storage: Raw {
        get {
            return (_storage[0], _storage[1], _storage[2], _storage[3], _storage[4], _storage[5], _storage[6], _storage[7], _storage[8], _storage[9], _storage[10], _storage[11])
        }
        set {
            self._storage = [newValue.0, newValue.1, newValue.2, newValue.3, newValue.4, newValue.5, newValue.6, newValue.7, newValue.8, newValue.9, newValue.10, newValue.11]
        }
    }
    
    internal var _storage: Bytes
    
    private static let counterQueue = DispatchQueue(label: "org.mongokitten.bson.oidcounter")
    
    /// Generate a new random ObjectId.
    public init() {
        var data = Bytes()
        
        let epoch = Int32(time(nil))
        
        // Take the current UNIX epoch as Int32 and take it's bytes
        data += epoch.makeBigEndianBytes()
        
        // Take a random number
        data += ObjectId.random.makeBytes()
        
        // And add a counter as 2 bytes and increment it
        ObjectId.counterQueue.sync {
            data += ObjectId.counter.makeBytes()
            ObjectId.counter = ObjectId.counter &+ 1
        }
        
        self._storage = data
    }
    
    /// Initialize a new ObjectId from given Hexadecimal string, such as "0123456789abcdef01234567".
    ///
    /// **Note that this string should always be a valid hexadecimal string of 24 characters.**
    ///
    /// Throws errors in case of an invalid string (e.g. wrong length)
    public init(_ hexString: String) throws {
        guard hexString.characters.count == 24 else {
            throw DeserializationError.InvalidObjectIdLength
        }
        
        var data = Bytes()
        
        var gen = hexString.characters.makeIterator()
        while let c1 = gen.next(), let c2 = gen.next() {
            let s = String([c1, c2])
            
            guard let d = Byte(s, radix: 16) else {
                break
            }
            
            data.append(d)
        }
        
        guard data.count == 12 else {
            throw DeserializationError.InvalidObjectIdLength
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
    public init(bytes data: Bytes) throws {
        guard data.count == 12 else {
            throw DeserializationError.invalidElementSize
        }
        
        self._storage = data
    }
    
    /// The 12 bytes represented as 24-character hex-string
    public var hexString: String {
        var bytes = Bytes()
        bytes.reserveCapacity(24)
        
        for byte in _storage {
            bytes.append(radix16table[Int(byte / 16)])
            bytes.append(radix16table[Int(byte % 16)])
        }
        
        return String(bytes: bytes, encoding: .utf8)!
    }
    
    public var epochSeconds: Int32 {
        let timeData = Data(bytes: _storage[0...3])
        return Int32(bigEndian:timeData.withUnsafeBytes { $0.pointee } )        
    }


    public var epoch: Date {
        let timeData = Data(bytes: _storage[0...3])
        let epoch = UInt32(bigEndian: timeData.withUnsafeBytes { $0.pointee } )

        return Date(timeIntervalSince1970: Double(epoch))
    }
}

extension ObjectId: Hashable {
    /// Returns a Boolean value indicating whether two values are equal.
    ///
    /// Equality is the inverse of inequality. For any values `a` and `b`,
    /// `a == b` implies that `a != b` is `false`.
    ///
    /// - Parameters:
    ///   - lhs: A value to compare.
    ///   - rhs: Another value to compare.
    public static func ==(lhs: ObjectId, rhs: ObjectId) -> Bool {
        return lhs._storage == rhs._storage
    }
    
    public var hashValue: Int {
        let epoch = self.epochSeconds
        let random = _storage[4...7].makeInt32()
        let increment = _storage[8...11].makeInt32()
        
        let total: Int32 = epoch &+ random &+ increment
        
        return Int(total)
    }
}

private let radix16table: Bytes = [0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x61, 0x62, 0x63, 0x64, 0x65, 0x66]
