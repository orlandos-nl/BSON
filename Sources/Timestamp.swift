//
//  Timestamp.swift
//  BSON
//
//  Created by Joannis Orlandos on 23/01/16.
//  Copyright © 2016 Robbert Brandsma. All rights reserved.
//

import Foundation

/// Timestamp is a special internal MongoDB type
public struct Timestamp : BSONElementConvertible {
    public var elementType: ElementType {
        return .Timestamp
    }
    
    public var bsonData: [UInt8] {
        return storage.bsonData
    }
    
    public static var bsonLength: BsonLength {
        return Int64.bsonLength
    }
    
    public static func instantiate(bsonData data: [UInt8]) throws -> Timestamp {
        return self.init(try Int64.instantiate(bsonData: data))
    }
    
    public static func instantiate(bsonData data: [UInt8], inout consumedBytes: Int, type: ElementType) throws -> Timestamp {
        return self.init(try Int64.instantiate(bsonData: data, consumedBytes: &consumedBytes, type: .Int64))
    }
    
    private init(_ s: Int64) { storage = s }
    private var storage: Int64
}