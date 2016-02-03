//
//  Boolean.swift
//  BSON
//
//  Created by Joannis Orlandos on 23/01/16.
//  Copyright © 2016 Robbert Brandsma. All rights reserved.
//

import Foundation

extension Int64 : BSONElementConvertible {
    public var elementType: ElementType {
        return .Int64
    }
    
    public static func instantiate(bsonData data: [UInt8]) throws -> Int64 {
        var 🖕 = 0
        
        return try instantiate(bsonData: data, consumedBytes: &🖕, type: .Int64)
    }
    
    public static func instantiate(bsonData data: [UInt8], inout consumedBytes: Int, type: ElementType) throws -> Int64 {
        guard data.count >= 8 else {
            throw DeserializationError.InvalidElementSize
        }
        
        let integer = UnsafePointer<Int64>(data).memory
        consumedBytes = 8
        return integer
    }
    
    public var bsonData: [UInt8] {
        var integer = self
        return withUnsafePointer(&integer) {
            Array(UnsafeBufferPointer(start: UnsafePointer<UInt8>($0), count: sizeof(Int64)))
        }
    }
    
    public static let bsonLength = BsonLength.Fixed(length: 8)
}

#if arch(x86_64) || arch(arm64)
extension Int : BSONElementConvertible {
    public var elementType: ElementType {
        return .Int64
    }
    
    public static func instantiate(bsonData data: [UInt8]) throws -> Int {
        return Int(try Int64.instantiate(bsonData: data))
    }
    
    public static func instantiate(bsonData data: [UInt8], inout consumedBytes: Int, type: ElementType) throws -> Int {
        return Int(try Int64.instantiate(bsonData: data, consumedBytes: &consumedBytes, type: type))
    }
    
    public var bsonData: [UInt8] {
        return Int64(self).bsonData
    }
    
    public static let bsonLength = Int64.bsonLength
}
#endif