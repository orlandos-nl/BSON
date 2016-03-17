//
//  Timestamp.swift
//  BSON
//
//  Created by Joannis Orlandos on 23/01/16.
//  Copyright © 2016 Robbert Brandsma. All rights reserved.
//

import Foundation

/// Timestamp is a special internal MongoDB type
public struct Timestamp : BSONElement {
    /// .Timestamp
    public var elementType: ElementType {
        return .Timestamp
    }
    
    /// Ready this timestamp for storing
    public var bsonData: [UInt8] {
        return storage.bsonData
    }
    
    /// Timestamp.bsonLength = Int64.bsonLength
    public static var bsonLength: BSONLength {
        return Int64.bsonLength
    }
    
    /// Instantiate a timestamp from BSON data (8 bytes or more)
    public static func instantiate(bsonData data: [UInt8]) throws -> Timestamp {
        return self.init(try Int64.instantiate(bsonData: data))
    }
    
    /// Instantiate a timestamp from BSON data (8 bytes or more)
    public static func instantiate(bsonData data: [UInt8], consumedBytes: inout Int, type: ElementType) throws -> Timestamp {
        return self.init(try Int64.instantiate(bsonData: data, consumedBytes: &consumedBytes, type: .Int64))
    }
    
    /// Initialize this timestamp instance.
    private init(_ s: Int64) { storage = s }
    
    /// The storage of the timestamp. Note that this is in an undocumented format.
    public var storage: Int64
    
    public var bsonDescription: String {
        return "Timestamp"
    }
}

extension Timestamp : Equatable {}
public func ==(left: Timestamp, right: Timestamp) -> Bool {
    return left.storage == right.storage
}