//
//  Boolean.swift
//  BSON
//
//  Created by Joannis Orlandos on 23/01/16.
//  Copyright © 2016 Robbert Brandsma. All rights reserved.
//

import Foundation

extension Int64 : BSONElement {
    /// .Int64
    public var elementType: ElementType {
        return .Int64
    }
    
    /// Restore given Int64 from storage
    public static func instantiate(bsonData data: [UInt8]) throws -> Int64 {
        var 🖕 = 0
        
        return try instantiate(bsonData: data, consumedBytes: &🖕, type: .Int64)
    }
    
    /// Restore given Int64 from storage
    public static func instantiate(bsonData data: [UInt8], inout consumedBytes: Int, type: ElementType) throws -> Int64 {
        guard data.count >= 8 else {
            throw DeserializationError.InvalidElementSize
        }
        
        let integer = UnsafePointer<Int64>(data).memory
        consumedBytes = 8
        return integer
    }
    
    /// Convert given Int64 to it's storage format
    public var bsonData: [UInt8] {
        var integer = self
        return withUnsafePointer(&integer) {
            Array(UnsafeBufferPointer(start: UnsafePointer<UInt8>($0), count: sizeof(Int64)))
        }
    }
    
    /// Always .Fixed(8)
    public static let bsonLength = BSONLength.Fixed(length: 8)
    
    public var bsonDescription: String {
        return "Int64(\(self))"
    }
}

#if arch(x86_64) || arch(arm64)
extension Int : BSONElement {
    /// On 64-bit platforms, .Int64
    public var elementType: ElementType {
        return .Int64
    }
    
    /// The same as Int64.instantiate
    public static func instantiate(bsonData data: [UInt8]) throws -> Int {
        return Int(try Int64.instantiate(bsonData: data))
    }

    /// The same as Int64.instantiate
    public static func instantiate(bsonData data: [UInt8], inout consumedBytes: Int, type: ElementType) throws -> Int {
        return Int(try Int64.instantiate(bsonData: data, consumedBytes: &consumedBytes, type: type))
    }

    /// The same as Int64.bsonData
    public var bsonData: [UInt8] {
        return Int64(self).bsonData
    }
    
    /// The same as Int64.bsonLength
    public static let bsonLength = Int64.bsonLength
    
    public var bsonDescription: String {
        return "\(self)"
    }
}
#endif