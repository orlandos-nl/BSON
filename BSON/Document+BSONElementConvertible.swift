//
//  Document+BSONElementConvertible.swift
//  BSON
//
//  Created by Robbert Brandsma on 03-02-16.
//  Copyright © 2016 Robbert Brandsma. All rights reserved.
//

import Foundation

extension Document : BSONElementConvertible {
    public var elementType: ElementType {
        return self.validatesAsArray() ? .Array : .Document
    }
    
    public var bsonData: [UInt8] {
        var body = [UInt8]()
        var length = 4
        
        for (key, element) in elements.sort({ $0.0 < $1.0 }) {
            body += [element.elementType.rawValue]
            body += key.cStringBsonData
            body += element.bsonData
        }
        
        body += [0x00]
        length += body.count
        
        var finalData = Int32(length).bsonData
        finalData.appendContentsOf(body)
        
        return finalData
    }
    
    public static func instantiate(bsonData data: [UInt8]) throws -> Document {
        var 🖕 = 0
        
        return try instantiate(bsonData: data, consumedBytes: &🖕)
    }
    
    public static func instantiate(bsonData data: [UInt8], inout consumedBytes: Int) throws -> Document {
        return try Document(data: data, consumedBytes: &consumedBytes)
    }
    
    public static let bsonLength = BsonLength.Undefined
}
