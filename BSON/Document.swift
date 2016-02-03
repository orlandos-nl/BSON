//
//  Document.swift
//  BSON
//
//  Created by Robbert Brandsma on 23-01-16.
//  Copyright © 2016 Robbert Brandsma. All rights reserved.
//

import Foundation

public struct Document {
    internal var elements = [String : BSONElementConvertible]()
    
    public init(data: NSData) throws {
        var byteArray = [UInt8](count: data.length, repeatedValue: 0)
        data.getBytes(&byteArray, length: byteArray.count)
        
        var 🖕 = 0
        
        try self.init(data: byteArray, consumedBytes: &🖕)
    }
    
    public init(data: [UInt8]) throws {
        var 🖕 = 0
        try self.init(data: data, consumedBytes: &🖕)
    }
    
    internal init(data: [UInt8], inout consumedBytes: Int) throws {
        // A BSON document cannot be smaller than 5 bytes (which would be an empty document)
        guard data.count >= 5 else {
            throw DeserializationError.InvalidDocumentLength
        }
        
        // The first four bytes of a document represent the total size of the document
        let documentLength = Int(Int32(littleEndian: UnsafePointer<Int32>(data).memory))
        guard data.count >= documentLength else {
            throw DeserializationError.InvalidDocumentLength
        }
        
        defer {
            consumedBytes = documentLength
        }
        
        // Parse! Loop over the element list.
        var position = 4
        while position < documentLength {
            // The first byte in an element is the element type
            let elementTypeValue = data[position]
            position += 1
            
            guard let elementType = ElementType(rawValue: elementTypeValue) else {
                if elementTypeValue == 0x00 && position == documentLength {
                    return
                } else if elementTypeValue == 0x00 {
                    // unexpected end of document
                    throw DeserializationError.ParseError
                }
                
                throw DeserializationError.UnknownElementType
            }
            
            // Now that we have the type, parse the name
            guard let stringTerminatorIndex = data[position..<documentLength].indexOf(0) else {
                throw DeserializationError.ParseError
            }
            
            let keyData = Array(data[position...stringTerminatorIndex - 1])
            let elementName = try String.instantiateFromCString(bsonData: keyData)
            
            position = stringTerminatorIndex + 1
            
            // We now have the key of the element and are at the position of the data itself. Let's intialize it.
            let length = elementType.type.bsonLength
            let elementData: [UInt8]
            switch length {
            case .Fixed(let bsonLength):
                elementData = Array(data[position..<position+bsonLength])
            case .Undefined:
                elementData = Array(data[position..<documentLength])
            case .NullTerminated:
                guard let terminatorIndex = data[(position + 4)..<data.endIndex].indexOf(0) else {
                    throw DeserializationError.ParseError
                }
                
                elementData = Array(data[position...terminatorIndex])
            }
            
            var consumedElementBytes = -1
            let result = try elementType.type.instantiate(bsonData: elementData, consumedBytes: &consumedElementBytes, type: elementType)
            
            if consumedElementBytes == -1 {
                throw DeserializationError.ParseError
            }
            
            if case .Fixed(let bsonLength) = length where consumedElementBytes != bsonLength {
                // Invalid!
                throw DeserializationError.InvalidElementSize
            }
            
            position += consumedElementBytes
            
            self.elements[elementName] = result
        }
    }
}

extension Document {
    public static func instantiateAll(data: [UInt8]) throws -> [Document] {
        var currentDataIndex = 0
        var documents = [Document]()
        while currentDataIndex < data.count {
            var consumedBytes = 0
            documents.append(try Document(data: Array(data[currentDataIndex..<data.count]), consumedBytes: &consumedBytes))
            
            guard consumedBytes > 0 else {
                throw DeserializationError.ParseError
            }
            
            currentDataIndex += consumedBytes
        }
        return documents
    }
}

extension Document {
    /// Returns true if this Document is an array and false otherwise.
    func validatesAsArray() -> Bool {
        var current = -1
        for (key, _) in self.elements {
            guard let index = Int(key) else {
                return false
            }
            
            if current == index-1 {
                current += 1
            } else {
                return false
            }
        }
        return true
    }
}

extension Document : CustomStringConvertible {
    public var description: String {
        return elements.description
    }
}
