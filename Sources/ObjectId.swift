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

public typealias RawObjectId = (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8)

#if os(Linux)
    private var random: UInt8 = Int32(rand()).bsonData[0]
#else
    private var random: UInt8 = UInt8(arc4random_uniform(255))
#endif
private var counter: Int16 = 0

/// Generate a new random ObjectId.
public func ObjectId() -> Value {
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
    data += [random]
    
    // And add a counter as 2 bytes and increment it
    data += counter.bsonData
    counter += 1
    
    return .objectId((data[0], data[1], data[2], data[3], data[4], data[5], data[6], data[7], data[8], data[9], data[10], data[11]))
}

/// Initialize a new ObjectId from given Hexadecimal string, such as "0123456789abcdef01234567".
///
/// **Note that this string should always be a valid hexadecimal string of 24 characters.**
///
/// Throws errors in case of an invalid string (e.g. wrong length)
public func ObjectId(_ hexString: String) throws -> Value {
    guard hexString.characters.count == 24 else {
        throw DeserializationError.ParseError
    }
    
    var data = [UInt8]()
    
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

    return .objectId((data[0], data[1], data[2], data[3], data[4], data[5], data[6], data[7], data[8], data[9], data[10], data[11]))
}

public func ObjectId(bsonData data: [UInt8]) throws -> Value {
    guard data.count == 12 else {
        throw DeserializationError.InvalidElementSize
    }
    
    return .objectId((data[0], data[1], data[2], data[3], data[4], data[5], data[6], data[7], data[8], data[9], data[10], data[11]))
}