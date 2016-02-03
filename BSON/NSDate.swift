//
//  NSDate.swift
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
        var 🖕 = 0
        
        return try instantiate(bsonData: data, consumedBytes: &🖕)
    }
    
    public static func instantiate(bsonData data: [UInt8], inout consumedBytes: Int) throws -> Self {
        let interval = try Int64.instantiate(bsonData: data, consumedBytes: &consumedBytes)
        let date = self.init(timeIntervalSinceReferenceDate: Double(interval) - NSTimeIntervalSince1970)
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