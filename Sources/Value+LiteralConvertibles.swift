//
//  Value-LiteralConvertibles.swift
//  BSON
//
//  Created by Robbert Brandsma on 18-04-16.
//
//

import Foundation

extension Value : IntegerLiteralConvertible {
    public init(integerLiteral: Int) {
        self = .int64(Int64(integerLiteral))
    }
}

extension Value : StringLiteralConvertible {
    public init(stringLiteral value: String) {
        self = .string(value)
    }
    
    public init(extendedGraphemeClusterLiteral value: String) {
        self = .string(value)
    }
    
    public init(unicodeScalarLiteral value: String) {
        self = .string(value)
    }
}

extension Value : BooleanLiteralConvertible {
    public init(booleanLiteral value: Bool) {
        self = .boolean(value)
    }
}

extension Value : DictionaryLiteralConvertible {
    public init(dictionaryLiteral elements: (String, Value)...) {
        self = .document(Document(dictionaryElements: elements))
    }
}

extension Value : ArrayLiteralConvertible {
    public init(arrayLiteral elements: Value...) {
        self = .array(Document(array: elements))
    }
}

extension Value : FloatLiteralConvertible {
    public init(floatLiteral value: Double) {
        self = .double(value)
    }
}