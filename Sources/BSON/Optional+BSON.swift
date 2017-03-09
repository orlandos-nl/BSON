//
//  Optional+BSON.swift
//  BSON
//
//  Created by Robbert Brandsma on 13-02-17.
//
//

import Foundation

extension Optional where Wrapped == Primitive {
    
    public subscript(parts: SubscriptExpressionType...) -> Primitive? {
        get {
            return (self as? Document)?[parts]
        }
        set {
            var document = (self as? Document) ?? [:]
            document[parts] = newValue
            self = document
        }
    }
    
    /// Performs a byte-to-byte comparison of both primitives, and returns `true` if they are equal
    public static func ===(lhs: Primitive?, rhs: Primitive?) -> Bool {
        // Both values nil -> equal
        if lhs == nil && rhs == nil {
            return true
        }
        
        // One of the values nil -> not equal
        guard let lhs = lhs, let rhs = rhs else {
            return false
        }
        
        return lhs.makeBinary() == rhs.makeBinary()
    }
}
