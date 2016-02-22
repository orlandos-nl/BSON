//
//  Document.swift
//  BSON
//
//  Created by Robbert Brandsma on 23-01-16.
//  Copyright © 2016 Robbert Brandsma. All rights reserved.
//

import Foundation

/// The base type for all BSON data, defined in the spec as:
///
/// `document	::=	int32 e_list "\x00"`
///
/// A document is comparable with a Swift `Array`or `Dictionary`. It can thus be initialized
/// by using an array or dictionary literal:
///
/// ```
/// let d: Document = ["key": "value"]
/// let a: Document = ["value 1", "value 2"]
/// ```
///
/// In the BSON specification, the following is said about BSON arrays: 
///
/// Array - The document for an array is a normal BSON document with integer values for the keys, starting with 0 and continuing sequentially. For example, the array `['red', 'blue']` would be encoded as the document `{'0': 'red', '1': 'blue'}`. The keys must be in ascending numerical order.
/// 
/// Because this BSON library exports all documents alphabetically, every document only numerical subsequential keys starting at '0' will be treated as an array.
public struct Document {
    /// Element storage
    internal var elements = [String : BSONElement]()
    
    /// Initialize a BSON document with the data from the given Foundation `NSData` object.
    /// 
    /// Will throw a `DeserializationError` when the document is invalid.
    public init(data: NSData) throws {
        var byteArray = [UInt8](count: data.length, repeatedValue: 0)
        data.getBytes(&byteArray, length: byteArray.count)
        
        var 🖕 = 0
        
        try self.init(data: byteArray, consumedBytes: &🖕)
    }
    
    /// Initialize a BSON document with the given byte array.
    ///
    /// Will throw a `DeserializationError` when the document is invalid.
    public init(data: [UInt8]) throws {
        var 🖕 = 0
        try self.init(data: data, consumedBytes: &🖕)
    }
    
    /// Internal initializer used by all other initializers and for initializing embedded documents.
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
            
            let keyData = Array(data[position...stringTerminatorIndex])
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
    /// Instantiates zero or more `Document`s from the given data. This data is formatted like this:
    /// `let data = document1.bsonData + document2.bsonData`, so just multiple documents concatenated.
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
    /// Returns the description of all elements in this document. Not ordered correctly.
    public var description: String {
        return elements.description
    }
}
