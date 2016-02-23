//
//  Null.swift
//  BSON
//
//  Created by Robbert Brandsma on 28-01-16.
//  Copyright © 2016 Robbert Brandsma. All rights reserved.
//

import Foundation

/// The BSON `NullValue`, as documented in the BSON spec.
public struct Null : BSONElement {
    /// Create a new `Null` for storing in BSON.
    public init() {}
    
    /// .NullValue
    public var elementType: ElementType {
        return .NullValue
    }
    
    /// Here, return the same data as you would accept in the initializer
    public var bsonData: [UInt8] {
        return []
    }
    
    /// The length of Null is 0.
    public static var bsonLength: BSONLength {
        return .Fixed(length: 0)
    }
    
    /// Always just returns Null() and sets consumedBytes to 0.
    public static func instantiate(bsonData data: [UInt8], inout consumedBytes: Int, type: ElementType) throws -> Null {
        consumedBytes = 0
        return Null()
    }
    
    /// Always just returns Null().
    public static func instantiate(bsonData data: [UInt8]) throws -> Null {
        return Null()
    }
    
    public var bsonDescription: String {
        return "Null()"
    }
}