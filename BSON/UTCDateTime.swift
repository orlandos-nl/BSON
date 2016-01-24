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
        let interval = try Int.instantiate(bsonData: data)
        print(interval)
        return self.init(timeIntervalSince1970: Double(interval))
    }
    
    public var bsonData: [UInt8] {
        var integer = Int(self.timeIntervalSince1970)
        return withUnsafePointer(&integer) {
            Array(UnsafeBufferPointer(start: UnsafePointer<UInt8>($0), count: sizeof(Int)))
        }
    }
}