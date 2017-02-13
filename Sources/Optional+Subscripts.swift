//
//  Optional+Subscripts.swift
//  BSON
//
//  Created by Robbert Brandsma on 13-02-17.
//
//

import Foundation

extension Optional where Wrapped == BSONPrimitive {
    
    public subscript(parts: SubscriptExpressionType...) -> BSONPrimitive? {
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
