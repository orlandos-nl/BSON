//
//  Integer16.swift
//  BSON
//
//  Created by Joannis Orlandos on 26/01/16.
//  Copyright © 2016 Robbert Brandsma. All rights reserved.
//

import Foundation

// For BSONElement-like behavior. No full support because this isn't a BSON type.
internal extension Int16 {
    internal static func instantiate(bsonData data: [UInt8]) throws -> Int16 {
        guard data.count >= 2 else {
            throw DeserializationError.InvalidElementSize
        }
        
        let integer = UnsafePointer<Int16>(data).pointee
        return integer
    }
    
    internal var bsonData: [UInt8] {
        var integer = self
        return withUnsafePointer(&integer) {
            Array(UnsafeBufferPointer(start: UnsafePointer<UInt8>($0), count: sizeof(Int16)))
        }
    }
}