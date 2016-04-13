//
//  NSDate.swift
//  BSON
//
//  Created by Joannis Orlandos on 24/01/16.
//  Copyright © 2016 Robbert Brandsma. All rights reserved.
//

import Foundation

extension NSDate : BSONElement {
    /// .DateTime
    public var elementType: ElementType {
        return .DateTime
    }
    
    /// Instantiate an NSDate from a BSON .DateTime
    public static func instantiate(bsonData data: [UInt8]) throws -> Self {
        var 🖕 = 0
        
        return try instantiate(bsonData: data, consumedBytes: &🖕, type: .DateTime)
    }
    
    /// Instantiate an NSDate from a BSON .DateTime
    public static func instantiate(bsonData data: [UInt8], consumedBytes: inout Int, type: ElementType) throws -> Self {
        let interval = try Int64.instantiate(bsonData: data, consumedBytes: &consumedBytes, type: .Int64)
        
        #if os(Linux)
            // if we don't do this, we get an error because open source Foundation's init(timeIntervalSince1970:) isn't required.
            let other_date = NSDate(timeIntervalSince1970: Double(interval) / 1000)
            let date = self.init(timeIntervalSinceReferenceDate: other_date.timeIntervalSinceReferenceDate)
        #else
            let date = self.init(timeIntervalSince1970: Double(interval) / 1000) // BSON time is in ms
        #endif
        
        return date
    }
    
    /// Convert to BSON .DateTime
    public var bsonData: [UInt8] {
        var integer = Int(self.timeIntervalSince1970) * 1000
        return withUnsafePointer(&integer) {
            Array(UnsafeBufferPointer(start: UnsafePointer<UInt8>($0), count: sizeof(Int)))
        }
    }
    
    /// BSON DateTime is always 8 bytes
    public static let bsonLength = BSONLength.Fixed(length: 8)
    
    public var bsonDescription: String {
        return "NSDate(timeIntervalSince1970: \(self.timeIntervalSince1970))"
    }
}