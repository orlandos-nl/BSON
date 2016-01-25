//
//  UTCDateTime.swift
//  BSON
//
//  Created by Joannis Orlandos on 24/01/16.
//  Copyright © 2016 Robbert Brandsma. All rights reserved.
//

import Foundation

extension NSDate : BSONElementConvertible {
    public var elementType: ElementType {
        return .DateTime
    }
    
    public static func instantiate(bsonData data: [UInt8]) throws -> Self {
        var ditched = 0
        
        return try instantiate(bsonData: data, consumedBytes: &ditched)
    }
    
    public static func instantiate(bsonData data: [UInt8], inout consumedBytes: Int) throws -> Self {
        var ditched = 0
        
        let interval = try Int.instantiate(bsonData: data, consumedBytes: &ditched)
        let date = self.init(timeIntervalSince1970: Double(interval))
        consumedBytes = 8
        return date
    }
    
    public var bsonData: [UInt8] {
        var integer = Int(self.timeIntervalSince1970)
        return withUnsafePointer(&integer) {
            Array(UnsafeBufferPointer(start: UnsafePointer<UInt8>($0), count: sizeof(Int)))
        }
    }
    
    public static let bsonLength = BsonLength.Fixed(length: 8)
}