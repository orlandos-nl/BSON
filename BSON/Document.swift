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
        var 🖕 = 0
        
        return try instantiate(bsonData: data, consumedBytes: &🖕)
    }
    
    public static func instantiate(bsonData data: [UInt8], inout consumedBytes: Int) throws -> Document {
        return try Document(data: data, consumedBytes: &consumedBytes)
    }
    
    public static let bsonLength = BsonLength.Undefined
}

extension Document : ArrayLiteralConvertible {
    public init(array: [BSONElementConvertible]) {
        for e in array {
            self.elements[self.elements.count.description] = e
        }
    }
    
    /// For now.. only accept BSONElementConvertible
    public init(arrayLiteral arrayElements: AbstractBSONBase...) {
        self.init(native: arrayElements)
    }
}

extension Document : DictionaryLiteralConvertible {
    /// Create an instance initialized with `elements`.
    public init(dictionaryLiteral dictionaryElements: (String, AbstractBSONBase)...) {
        var dict = [String:AbstractBSONBase]()
        
        for (k, v) in dictionaryElements {
            dict[k] = v
        }
        
        self.init(native: dict)
    }
}

// TODO: Add assignment subscript

extension Document {
    private init(native: [AbstractBSONBase]) {
        // TODO: Call other initializer with a dictionary from this array
        var d = [String:AbstractBSONBase]()
        
        for e in native {
            d[String(d.count)] = e
        }
        
        self.init(native: d)
    }
    
    private init(native: [String: AbstractBSONBase]) {
        for (key, element) in native {
            switch element {
            case let element as BSONElementConvertible:
                elements[key] = element
            case let element as BSONArrayConversionProtocol:
                elements[key] = Document(native: element.getAbstractArray())
            case let element as BSONDictionaryConversionProtocol:
                elements[key] = Document(native: element.getAbstractDictionary())
            default:
                print("WARNING: Document cannot be initialized with an element of type \(element.dynamicType)")
            }
        }
    }
}

extension Document : SequenceType {
    public typealias Key = String
    public typealias FooValue = BSONElementConvertible
    public typealias Index = DictionaryIndex<Key, FooValue>
    
    // Remap everything to elements
    public var startIndex: DictionaryIndex<Key, FooValue> {
        return elements.startIndex
    }
    
    public var endIndex: DictionaryIndex<Key, FooValue> {
        return elements.endIndex
    }
    
    public func indexForKey(key: Key) -> DictionaryIndex<Key, FooValue>? {
        return elements.indexForKey(key)
    }
    
    public subscript (key: Key) -> FooValue? {
        return elements[key]
    }
    
    // Add extra subscript for Integers since a Document can also be a BSON Array
    public subscript (key: Int) -> BSONElementConvertible? {
        return self["\(key)"]
    }
    
    public subscript (position: DictionaryIndex<Key, FooValue>) -> (Key, FooValue) {
        return elements[position]
    }
    
    public mutating func updateValue(value: FooValue, forKey key: Key) -> FooValue? {
        return elements.updateValue(value, forKey: key)
    }
    
    // WORKS?
    public mutating func removeAtIndex(index: DictionaryIndex<Key, FooValue>) -> (Key, FooValue) {
        return elements.removeAtIndex(index)
    }
    
    public mutating func removeValueForKey(key: Key) -> FooValue? {
        return elements.removeValueForKey(key)
    }
    
    public mutating func removeAll(keepCapacity keepCapacity: Bool = false) {
        elements.removeAll()
    }
    
    public var count: Int {
        return elements.count
    }
    
    public func generate() -> DictionaryGenerator<Key, FooValue> {
        return elements.generate()
    }
    
    public var keys: LazyMapCollection<[Key : FooValue], Key> {
        return elements.keys
    }
    
    public var values: LazyMapCollection<[Key : FooValue], FooValue> {
        return elements.values
    }
    
    public var isEmpty: Bool {
        return elements.isEmpty
    }
}

extension Document : CustomStringConvertible {
    public var description: String {
        return elements.description
    }
}
