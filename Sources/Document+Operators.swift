//
//  Document+Operators.swift
//  BSON
//
//  Created by Robbert Brandsma on 15-03-16.
//  Copyright © 2016 Robbert Brandsma. All rights reserved.
//

import Foundation

public func +(lhs: Document, rhs: Document) -> Document {
    var lhs = lhs
    lhs.elements += rhs.elements
    return lhs
}