//
//  Document+LiteralConvertibles.swift
//  BSON
//
//  Created by Robbert Brandsma on 03-02-16.
//  Copyright © 2016 Robbert Brandsma. All rights reserved.
//

import Foundation

extension Document : ArrayLiteralConvertible {
    /// Initialize a Document using an array of `BSONElementConvertible`s.
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
