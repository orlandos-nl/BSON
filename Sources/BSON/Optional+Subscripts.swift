//
//  Optional+Subscripts.swift
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

}
