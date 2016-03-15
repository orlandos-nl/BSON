//
//  Document+BSONElement.swift
//  BSON
//
//  Created by Robbert Brandsma on 03-02-16.
//  Copyright © 2016 Robbert Brandsma. All rights reserved.
//

import Foundation

extension Document : BSONElement {
    /// .Array or .Document, depending on validatesAsArray()
    public var elementType: ElementType {
        return self.validatesAsArray() ? .Array : .Document
    }
    
    /// Serialize the document, ready to store as a BSON file or sending over the network.
    /// You may concatenate output of this method into one long array, and instantiate that using
    /// `instantiateMultiple(...)`
    public var bsonData: [UInt8] {
        var body = [UInt8]()
        var length = 4
        
        for (key, element) in elements {
            body += [element.elementType.rawValue]
            body += key.cStringBsonData
            body += element.bsonData
        }
        
        body += [0x00]
        length += body.count
        
        let finalData = Int32(length).bsonData + body
        
        return finalData
    }
    
    /// Used internally
    public static func instantiate(bsonData data: [UInt8]) throws -> Document {
        var 🖕 = 0
        
        return try instantiate(bsonData: data, consumedBytes: &🖕, type: .Document)
    }
    
    /// Used internally
    public static func instantiate(bsonData data: [UInt8], inout consumedBytes: Int, type: ElementType) throws -> Document {
        return try Document(data: data, consumedBytes: &consumedBytes)
    }
    
    /// .Undefined
    public static let bsonLength = BSONLength.Undefined
    
    public var bsonDescription: String {
        var desc = "*["
        for (key, element) in self.elements {
            desc += "\(key.bsonDescription): \(element.bsonDescription),"
        }
        desc += "]"
        return desc
    }
}
