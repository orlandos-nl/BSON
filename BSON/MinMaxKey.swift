//
//  MinMaxKey.swift
//  BSON
//
//  Created by Robbert Brandsma on 01-02-16.
//  Copyright © 2016 Robbert Brandsma. All rights reserved.
//

import Foundation

public struct MinKey : BSONElementConvertible {
    public init() {}
    
    public let elementType = ElementType.MinKey
    public let bsonData = [UInt8]()
    public static var bsonLength = BsonLength.Fixed(length: 0)
    public static func instantiate(bsonData data: [UInt8], inout consumedBytes: Int) throws -> MinKey {
        consumedBytes = 0
        return MinKey()
    }
    public static func instantiate(bsonData data: [UInt8]) throws -> MinKey {
        return MinKey()
    }
}

public struct MaxKey : BSONElementConvertible {
    public init() {}
    
    public let elementType = ElementType.MaxKey
    public let bsonData = [UInt8]()
    public static var bsonLength = BsonLength.Fixed(length: 0)
    public static func instantiate(bsonData data: [UInt8], inout consumedBytes: Int) throws -> MaxKey {
        consumedBytes = 0
        return MaxKey()
    }
    public static func instantiate(bsonData data: [UInt8]) throws -> MaxKey {
        return MaxKey()
    }
}