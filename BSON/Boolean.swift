//
//  Boolean.swift
//  BSON
//
//  Created by Joannis Orlandos on 23/01/16.
//  Copyright © 2016 Robbert Brandsma. All rights reserved.
//

import Foundation

extension Bool : BSONElementConvertible {
    public var elementType: ElementType {
        return .Boolean
    }
    
    /// The initializer expects the data for this element, starting AFTER the element type
    public static func instantiate(bsonData data: [UInt8]) throws -> Bool {
        guard data.count == 1 else {
            throw DeserializationError.InvalidDocumentLength
        }
        
        guard data.first == 0x00 || data.first == 0x01 else {
            throw DeserializationError.InvalidElementContents
        }
        
        return data.first == 0x00 ? false : true
    }
    
    /// Here, return the same data as you would accept in the initializer
    public var bsonData: [UInt8] {
        return self ? [0x01] : [0x00]
    }
}