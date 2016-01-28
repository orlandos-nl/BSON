//
//  Document.swift
//  BSON
//
//  Created by Robbert Brandsma on 23-01-16.
//  Copyright © 2016 Robbert Brandsma. All rights reserved.
//

import Foundation

public struct Document {
    var elements = [String : BSONElementConvertible]()
    
    init(data: NSData) throws {
        var byteArray = [UInt8](count: data.length, repeatedValue: 0)
        data.getBytes(&byteArray, length: byteArray.count)
        
        var ditched = 0
        
        try self.init(data: byteArray, consumedBytes: &ditched)
    }
    
    init(data: [UInt8], inout consumedBytes: Int) throws {
        // A BSON document cannot be smaller than 5 bytes (which would be an empty document)
        guard data.count >= 5 else {
            throw DeserializationError.InvalidDocumentLength
        }
        
        // The first four bytes of a document represent the total size of the document
        let documentLength = Int32(littleEndian: UnsafePointer<Int32>(data).memory)
        guard Int(documentLength) == data.count else {
            throw DeserializationError.InvalidDocumentLength
        }
        
        // Parse! Loop over the element list.
        var position = 4
        while position < Int(documentLength) {
            // The first byte in an element is the element type
            let elementTypeValue = data[position]
            position += 1
            
            guard let elementType = ElementType(rawValue: elementTypeValue) else {
                if elementTypeValue == 0x00 {
                    return
                }
                
                throw DeserializationError.UnknownElementType
            }
            
            // Now that we have the type, parse the name
            guard let stringTerminatorIndex = data[position..<data.endIndex].indexOf(0) else {
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
                let arrayLength = Int(try Int32.instantiate(bsonData: Array(data[position...position+3])))
                
                elementData = Array(data[position...Int(position+arrayLength-1)])
            case .NullTerminated:
                guard let terminatorIndex = data[(position + 4)..<data.endIndex].indexOf(0) else {
                    throw DeserializationError.ParseError
                }
                
                elementData = Array(data[position...terminatorIndex])
            }
            
            var consumedElementBytes = 0
            let result = try elementType.type.instantiate(bsonData: elementData, consumedBytes: &consumedElementBytes)
            
            if consumedElementBytes == 0 {
                consumedElementBytes = elementData.count
            }
            
            position += consumedElementBytes
            
            self.elements[elementName] = result
        }
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
        var ditched = 0
        
        return try instantiate(bsonData: data, consumedBytes: &ditched)
    }
    
    public static func instantiate(bsonData data: [UInt8], inout consumedBytes: Int) throws -> Document {
        return try Document.init(data: data, consumedBytes: &consumedBytes)
    }
    
    public static let bsonLength = BsonLength.Undefined
}

extension Document : ArrayLiteralConvertible {
    /// For now.. only accept BSONElementConvertible
    public init(arrayLiteral arrayElements: BSONElementConvertible...) {
        for element in arrayElements {
            elements[elements.count.description] = element
        }
    }
}

extension Document : DictionaryLiteralConvertible {
    /// Create an instance initialized with `elements`.
    public init(dictionaryLiteral dictionaryElements: (String, BSONElementConvertible)...) {
        for (key, element) in dictionaryElements {
            elements[key] = element
        }
    }
}