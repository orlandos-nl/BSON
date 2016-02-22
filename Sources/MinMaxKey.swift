//
//  MinMaxKey.swift
//  BSON
//
//  Created by Robbert Brandsma on 01-02-16.
//  Copyright © 2016 Robbert Brandsma. All rights reserved.
//

import Foundation

/// Special type which compares lower than all other possible BSON element values.
public struct MinKey : BSONElement {
    /// Create a new MinKey
    public init() {}
    
    /// .MinKey
    public let elementType = ElementType.MinKey
    
    /// Empty
    public let bsonData = [UInt8]()
    
    /// Zero bytes
    public static var bsonLength = BSONLength.Fixed(length: 0)
    
    /// Always returns MinKey()
    public static func instantiate(bsonData data: [UInt8], inout consumedBytes: Int, type: ElementType) throws -> MinKey {
        consumedBytes = 0
        return MinKey()
    }
    
    /// Always returns MinKey()
    public static func instantiate(bsonData data: [UInt8]) throws -> MinKey {
        return MinKey()
    }
}

/// Special type which compares higher than all other possible BSON element values.
public struct MaxKey : BSONElement {
    /// Create a new MaxKey
    public init() {}
    
    /// .MaxKey
    public let elementType = ElementType.MaxKey
    
    /// Empty
    public let bsonData = [UInt8]()
    
    /// Zero bytes
    public static var bsonLength = BSONLength.Fixed(length: 0)
    
    /// Always returns MaxKey()
    public static func instantiate(bsonData data: [UInt8], inout consumedBytes: Int, type: ElementType) throws -> MaxKey {
        consumedBytes = 0
        return MaxKey()
    }
    
    /// Always returns MaxKey()
    public static func instantiate(bsonData data: [UInt8]) throws -> MaxKey {
        return MaxKey()
    }
}