//
//  Value-LiteralConvertibles.swift
//  BSON
//
//  Created by Robbert Brandsma on 18-04-16.
//
//

import Foundation

extension Value : ExpressibleByIntegerLiteral {
    public init(integerLiteral: Int) {
        self = .int64(Int64(integerLiteral))
    }
}

extension Value : ExpressibleByStringLiteral {
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

extension Value : ExpressibleByBooleanLiteral {
    public init(booleanLiteral value: Bool) {
        self = .boolean(value)
    }
}

extension Value : ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (String, ValueConvertible)...) {
        self = .document(Document(dictionaryElements: elements))
    }
}

extension Value : ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: ValueConvertible...) {
        self = .array(Document(array: elements))
    }
}

extension Value : ExpressibleByFloatLiteral {
    public init(floatLiteral value: Double) {
        self = .double(value)
    }
}
