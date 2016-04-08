//
//  Document+Operators.swift
//  BSON
//
//  Created by Robbert Brandsma on 15-03-16.
//  Copyright © 2016 Robbert Brandsma. All rights reserved.
//

import Foundation

/// Combines the left and right document.
/// If the documents are arrays, the right document will be appended at the end of the left document.
/// If the documents aren't arrays, the value for the right document will be used for any key contained in both documents.
public func +(lhs: Document, rhs: Document) -> Document {
    let areArrays = lhs.validatesAsArray() && rhs.validatesAsArray()
    
    var new = lhs
    if areArrays {
        new.elements += rhs.elements
    
        new.enforceArray()
        
        return new
    } else {
        for (key, value) in rhs.elements {
            if let index = new.elements.index(where: {$0.0 == key}) {
                new.elements.remove(at: index)
            }
            
            new.elements.append((key, value))
        }
        return new
    }
}

public func +=(lhs: inout Document, rhs: Document) {
    lhs = lhs + rhs
}