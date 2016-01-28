//
//  ObjectID.swift
//  BSON
//
//  Created by Joannis Orlandos on 23/01/16.
//  Copyright © 2016 Robbert Brandsma. All rights reserved.
//

import Foundation

public struct ObjectID {
    public private(set) var data: [UInt8]
#if os(Linux)
    private static var random: UInt8 = Int32(rand()).bsonData[0]
#else
    private static var random: Uint8 = UInt8(arc4random_uniform(255))
#endif
    private static var counter: Int16 = 0
    
    public init(hexString: String) throws {
        data = hexString.characters.map { UInt8(String($0), radix: 16) }.flatMap{$0}
        
        guard data.count == 12 else {
            throw DeserializationError.ParseError
        }
    }
    
    public init(bsonData: [UInt8]) throws {
        data = bsonData
        
        guard data.count == 12 else {
            throw DeserializationError.ParseError
        }
    }
    
    public var hexString: String {
        return data.map{String($0, radix: 16, uppercase: false)}.joinWithSeparator("")
    }
    
    public static func generate() throws -> ObjectID {
        let currentTime = NSDate()
        
        var data = [UInt8]()
        
        // Take the current UNIX epoch as Int32 and take it's bytes
        data += try Int32.instantiate(bsonData: Array(currentTime.bsonData[0...3])).bsonData
        
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
        
        return try self.init(bsonData: data)
    }
}

extension ObjectID : BSONElementConvertible {
    public var elementType: ElementType {
        return .ObjectId
    }
    
    /// Here, return the same data as you would accept in the initializer
    public var bsonData: [UInt8] {
        return data
    }
    
    public static var bsonLength: BsonLength {
        return .Fixed(length: 12)
    }
    
    /// The initializer expects the data for this element, starting AFTER the element type
    public static func instantiate(bsonData data: [UInt8], inout consumedBytes: Int) throws -> ObjectID {
        let objectID = try self.init(bsonData: data)
        consumedBytes = data.count
        
        return objectID
    }
    
    public static func instantiate(bsonData data: [UInt8]) throws -> ObjectID {
        return try self.init(bsonData: data)
    }
}