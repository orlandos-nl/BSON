//
//  Document+LiteralConvertibles.swift
//  BSON
//
//  Created by Robbert Brandsma on 03-02-16.
//  Copyright © 2016 Robbert Brandsma. All rights reserved.
//

import Foundation

extension Document {
    public var arrayValue: [BSONElement] {
        return self.elements.map{$0.1}
    }
}

extension Document : ArrayLiteralConvertible {
    /// Initialize a Document using an array of `BSONElement`s.
    public init(array: [BSONElement]) {
        elements = array.map { ("", $0) }
        self.enforceArray()
    }
    
    /// For now.. only accept BSONElement
    public init(arrayLiteral arrayElements: BSONElement...) {
        self.init(array: arrayElements)
    }
    
    public mutating func enforceArray() {
        for i in 0..<elements.count {
            elements[i].0 = "\(i)"
        }
    }
}

extension Document : DictionaryLiteralConvertible {
    /// Create an instance initialized with `elements`.
    public init(dictionaryLiteral dictionaryElements: (String, BSONElement)...) {
        self.elements = dictionaryElements
    }
}

extension Document {
    internal init(native: [String: BSONElement]) {
        self.elements = native.map({ $0 })
    }
}
