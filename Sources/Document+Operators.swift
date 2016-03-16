//
//  Document+Operators.swift
//  BSON
//
//  Created by Robbert Brandsma on 15-03-16.
//  Copyright © 2016 Robbert Brandsma. All rights reserved.
//

import Foundation

public func +(lhs: Document, rhs: Document) -> Document {
    let areArrays = lhs.validatesAsArray() && rhs.validatesAsArray()
    
    var lhs = lhs
    lhs.elements += rhs.elements
    
    if areArrays {
        lhs.enforceArray()
    }
    
    return lhs
}

public func +=(inout lhs: Document, rhs: Document) {
    lhs.elements += rhs.elements
}