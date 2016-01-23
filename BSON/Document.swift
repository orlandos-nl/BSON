//
//  Document.swift
//  BSON
//
//  Created by Robbert Brandsma on 23-01-16.
//  Copyright © 2016 Robbert Brandsma. All rights reserved.
//

import Foundation

public struct Document {
    var elements: [String : BSONElementConvertible]
    
    init(data: NSData) throws {
        var byteArray = [UInt8](count: data.length, repeatedValue: 0)
        data.getBytes(&byteArray, length: byteArray.count)
        
        try self.init(data: byteArray)
    }
    
    init(data: [UInt8]) throws {
        // A BSON document cannot be smaller than 5 bytes (which would be an empty document)
        guard data.count >= 5 else {
            throw DeserializationError.InvalidDocumentLength
        }
        
        // The first four bytes of a document represent the total size of the document
        let documentLength = Int32(littleEndian: UnsafePointer<Int32>(data).memory)
        guard Int(documentLength) == data.count else {
            throw DeserializationError.InvalidDocumentLength
        }
        
        self.elements = [:]
    }
}