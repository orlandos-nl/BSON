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

public final class ObjectIdGenerator {
    public init() {}
    
    #if os(Linux)
        private var random: Int32 = {
            srand(UInt32(time(nil)))
            return rand()
        }()
    
        private var counter: Int32 = {
            srand(UInt32(time(nil)))
            return rand()
        }()
    #else
        private var random = arc4random_uniform(UInt32.max)
        private var counter = arc4random_uniform(UInt32.max)
    #endif
    
    public func generate() -> ObjectId {
        var data = Data(repeating: 0, count: 12)
        
        var epoch = Int32(time(nil)).bigEndian
        
        data.withUnsafeMutableBytes { (pointer: UnsafeMutablePointer<UInt8>) in
            memcpy(pointer, &epoch, 4)
            memcpy(pointer.advanced(by: 4), &self.random, 4)
            
            // And add a counter as 2 bytes and increment it
            memcpy(pointer.advanced(by: 8), &self.counter, 4)
            self.counter = self.counter &+ 1
        }
        
        return try! ObjectId(data: data)
    }
}

/// 12-byte unique ID
///
/// Defined as: `UNIX epoch time` + `machine identifier` + `process ID` + `random increment`
public struct ObjectId {
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
    
    internal var _storage: Data
    
    private static let generator = ObjectIdGenerator()
    private static let generatorQueue = DispatchQueue(label: "org.mongokitten.bson.oidcounter")
    
    /// Generate a new random ObjectId.
    public init() {
        self = ObjectId.generatorQueue.sync {
            return ObjectId.generator.generate()
        }
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
        
        var data = Data()
        
        var gen = hexString.characters.makeIterator()
        while let c1 = gen.next(), let c2 = gen.next() {
            let s = String([c1, c2])
            
            guard let d = UInt8(s, radix: 16) else {
                break
            }
            
            data.append(d)
        }
        
        guard data.count == 12 else {
            throw DeserializationError.InvalidObjectIdLength
        }
        
        self._storage = data
    }
    
    /// Initializes ObjectId with an array of bytes
    ///
    /// Throws when there are not exactly 12 bytes provided
    public init(data: Data) throws {
        guard data.count == 12 else {
            throw DeserializationError.invalidElementSize
        }
        
        self._storage = data
    }
    
    /// The 12 bytes represented as 24-character hex-string
    public var hexString: String {
        var data = Data()
        data.reserveCapacity(24)
        
        for byte in _storage {
            data.append(radix16table[Int(byte / 16)])
            data.append(radix16table[Int(byte % 16)])
        }
        
        return String(data: data, encoding: .utf8)!
    }
    
    public var epochSeconds: Int32 {
        let timeData = Data(_storage[..._storage.startIndex.advanced(by: 3)])
        return Int32(bigEndian: timeData.withUnsafeBytes { $0.pointee } )
    }


    public var epoch: Date {
        let timeData = Data(_storage[..._storage.startIndex.advanced(by: 3)])
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
        return _storage.withUnsafeBytes { (pointer: UnsafePointer<UInt8>) in
            return pointer.withMemoryRebound(to: Int32.self, capacity: 3) { pointer in
                return numericCast(self.epochSeconds &+ (pointer[1] &* 3) &+ (pointer[2] &* 8))
            }
        }
    }
}

extension ObjectId : CustomStringConvertible {
    public var description: String {
        return "ObjectId(\"\(hexString)\")"
    }
}

private let radix16table = Data([0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x61, 0x62, 0x63, 0x64, 0x65, 0x66])
