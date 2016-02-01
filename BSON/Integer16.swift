//
//  Integer16.swift
//  BSON
//
//  Created by Joannis Orlandos on 26/01/16.
//  Copyright © 2016 Robbert Brandsma. All rights reserved.
//

import Foundation

extension Int16 {
    public static func instantiate(bsonData data: [UInt8]) throws -> Int16 {
        var 🖕 = 0
        
        return try instantiate(bsonData: data, consumedBytes: &🖕)
    }
    
    public static func instantiate(bsonData data: [UInt8], inout consumedBytes: Int) throws -> Int16 {
        guard data.count == 2 else {
            throw DeserializationError.InvalidElementSize
        }
        
        let integer = UnsafePointer<Int16>(data).memory
        consumedBytes = 2
        return integer
    }
    
    public var bsonData: [UInt8] {
        var integer = self
        return withUnsafePointer(&integer) {
            Array(UnsafeBufferPointer(start: UnsafePointer<UInt8>($0), count: sizeof(Int16)))
        }
    }
}