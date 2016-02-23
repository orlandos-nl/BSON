//
//  Boolean.swift
//  BSON
//
//  Created by Joannis Orlandos on 23/01/16.
//  Copyright © 2016 Robbert Brandsma. All rights reserved.
//

import Foundation

extension Bool : BSONElement {
    /// .Boolean
    public var elementType: ElementType {
        return .Boolean
    }
    
    /// Instantiate a new Bool from BSON data
    public static func instantiate(bsonData data: [UInt8]) throws -> Bool {
        var 🖕 = 0
        
        return try instantiate(bsonData: data, consumedBytes: &🖕, type: .Boolean)
    }
    
    /// Instantiate a new Bool from BSON data
    public static func instantiate(bsonData data: [UInt8], inout consumedBytes: Int, type: ElementType) throws -> Bool {
        guard data.count >= 1 else {
            throw DeserializationError.InvalidDocumentLength
        }
        
        guard data.first == 0x00 || data.first == 0x01 else {
            throw DeserializationError.InvalidElementContents
        }
        
        consumedBytes = 1
        
        return data.first == 0x00 ? false : true
    }
    
    /// Here, return the same data as you would accept in the initializer
    public var bsonData: [UInt8] {
        return self ? [0x01] : [0x00]
    }
    
    /// A bool is always 1 byte
    public static let bsonLength = BSONLength.Fixed(length: 1)
    
    public var bsonDescription: String {
        return self ? "true" : "false"
    }
}