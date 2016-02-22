//
//  Boolean.swift
//  BSON
//
//  Created by Joannis Orlandos on 23/01/16.
//  Copyright © 2016 Robbert Brandsma. All rights reserved.
//

import Foundation

extension Int32 : BSONElement {
    /// .Int32
    public var elementType: ElementType {
        return .Int32
    }
    
    /// Instantiate from 4 bytes of BSON
    public static func instantiate(bsonData data: [UInt8]) throws -> Int32 {
        var 🖕 = 0
        
        return try instantiate(bsonData: data, consumedBytes: &🖕, type: .Int32)
    }

    /// Instantiate from 4 bytes of BSON
    public static func instantiate(bsonData data: [UInt8], inout consumedBytes: Int, type: ElementType) throws -> Int32 {
        guard data.count >= 4 else {
            throw DeserializationError.InvalidElementSize
        }
        
        let integer = UnsafePointer<Int32>(data).memory
        consumedBytes = 4
        return integer
    }
    
    /// Convert to 4 bytes
    public var bsonData: [UInt8] {
        var integer = self
        return withUnsafePointer(&integer) {
            Array(UnsafeBufferPointer(start: UnsafePointer<UInt8>($0), count: sizeof(Int32)))
        }
    }
    
    /// 4 bytes
    public static let bsonLength = BSONLength.Fixed(length: 4)
}