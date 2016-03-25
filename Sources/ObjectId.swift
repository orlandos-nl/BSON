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

/// The BSON/MongoDB ObjectId type (see: https://docs.mongodb.org/manual/reference/object-id/)
public struct ObjectId {
    /// Raw data for this ObjectId
    public private(set) var data: [UInt8]
    
#if os(Linux)
    private static var random: UInt8 = Int32(rand()).bsonData[0]
#else
    private static var random: UInt8 = UInt8(arc4random_uniform(255))
#endif
    private static var counter: Int16 = 0
    
    /// Initialize a new ObjectId from given Hexadecimal string, such as "0123456789abcdef01234567".
    ///
    /// **Note that this string should always be a valid hexadecimal string of 24 characters.**
    ///
    /// Throws errors in case of an invalid string (e.g. wrong length)
    public init(_ hexString: String) throws {
        guard hexString.characters.count == 24 else {
            throw DeserializationError.ParseError
        }
        
        data = []
        
        var gen = hexString.characters.makeIterator()
        while let c1 = gen.next(), c2 = gen.next() {
            let s = String([c1, c2])
            
            guard let d = UInt8(s, radix: 16) else {
                break
            }
            
            data.append(d)
        }
        
        guard data.count == 12 else {
            throw DeserializationError.ParseError
        }
    }
    
    /// Instantiate this ObjectId with the given data. Needs to be at least 12 bytes. Only the first 12 bytes are used.
    public init(bsonData: [UInt8]) throws {
        guard bsonData.count >= 12 else {
            throw DeserializationError.InvalidElementSize
        }
        
        data = Array(bsonData[0..<12])
    }
    
    /// Return the hexadecimal string of this ObjectId, eg "0123456789abcdef01234567"
    public var hexString: String {
        var hexString = data.map{String($0, radix: 16, uppercase: false)}.joined(separator: "")
        while hexString.characters.count < 24 {
            hexString = "0" + hexString
        }
        return hexString
    }
    
    /// Generate a new random ObjectId.
    public init() {
        let currentTime = NSDate()
        
        var data = [UInt8]()
        
        // Take the current UNIX epoch as Int32 and take it's bytes
        data += Int32(currentTime.timeIntervalSince1970).bsonData
        
        // Take the machine identifier
        // TODO: Change this to a MAC address
        data += Array(NSProcessInfo.processInfo().hostName.hash.bsonData[0...2])
        
        // Take the process identifier as 2 bytes
        data += Array(NSProcessInfo.processInfo().processIdentifier.bsonData[0...1])
        
        // Take a random number
        data += [ObjectId.random]
        
        // And add a counter as 2 bytes and increment it
        data += ObjectId.counter.bsonData
        ObjectId.counter += 1
        
        self.data = data
    }
}

extension ObjectId : BSONElement {
    /// .ObjectId
    public var elementType: ElementType {
        return .ObjectId
    }
    
    /// Raw data for storage in a BSON Document
    public var bsonData: [UInt8] {
        return data
    }
    
    /// .Fixed(length: 12)
    public static var bsonLength: BSONLength {
        return .Fixed(length: 12)
    }
    
    /// Used internally
    public static func instantiate(bsonData data: [UInt8], consumedBytes: inout Int, type: ElementType) throws -> ObjectId {
        let objectID = try self.init(bsonData: data)
        consumedBytes = 12
        
        return objectID
    }
    
    /// Used internally
    public static func instantiate(bsonData data: [UInt8]) throws -> ObjectId {
        return try self.init(bsonData: data)
    }

    /// Returns something like: ObjectId("0123456789abcdef01234567")
    public var bsonDescription: String {
        return "try! ObjectId(\"\(self.hexString)\")"
    }
}

extension ObjectId : Equatable {}
public func ==(left: ObjectId, right: ObjectId) -> Bool {
    return left.data == right.data
}