//
//  Null.swift
//  BSON
//
//  Created by Robbert Brandsma on 28-01-16.
//  Copyright © 2016 Robbert Brandsma. All rights reserved.
//

import Foundation

public struct Null : BSONElementConvertible {
    public var elementType: ElementType {
        return .NullValue
    }
    
    /// Here, return the same data as you would accept in the initializer
    public var bsonData: [UInt8] {
        return []
    }
    
    public static var bsonLength: BsonLength {
        return .Fixed(length: 0)
    }
    
    /// The initializer expects the data for this element, starting AFTER the element type
    public static func instantiate(bsonData data: [UInt8], inout consumedBytes: Int) throws -> Null {
        consumedBytes = 0
        return Null()
    }
    
    public static func instantiate(bsonData data: [UInt8]) throws -> Null {
        return Null()
    }
}