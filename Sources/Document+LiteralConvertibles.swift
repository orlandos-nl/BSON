//
//  Document+LiteralConvertibles.swift
//  BSON
//
//  Created by Robbert Brandsma on 03-02-16.
//  Copyright © 2016 Robbert Brandsma. All rights reserved.
//

import Foundation

extension Document : ArrayLiteralConvertible {
    /// Initialize a Document using an array of `BSONElement`s.
    public init(array: [BSONElement]) {
        for e in array {
            self.elements[self.elements.count.description] = e
        }
    }
    
    /// For now.. only accept BSONElement
    public init(arrayLiteral arrayElements: BSONElement...) {
        self.init(native: arrayElements)
    }
}

extension Document : DictionaryLiteralConvertible {
    /// Create an instance initialized with `elements`.
    public init(dictionaryLiteral dictionaryElements: (String, BSONElement)...) {
        var dict = [String:BSONElement]()
        
        for (k, v) in dictionaryElements {
            dict[k] = v
        }
        
        self.init(native: dict)
    }
}

extension Document {
    internal init(native: [BSONElement]) {
        // TODO: Call other initializer with a dictionary from this array
        var d = [String:BSONElement]()
        
        for e in native {
            d[String(d.count)] = e
        }
        
        self.init(native: d)
    }
    
    internal init(native: [String: BSONElement]) {
        self.elements = native
    }
}
