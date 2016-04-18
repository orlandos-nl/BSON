//
//  Element.swift
//  BSON
//
//  Created by Robbert Brandsma on 23-01-16.
//  Copyright © 2016 Robbert Brandsma. All rights reserved.
//

import Foundation

/// Represents the estimated length of a BSON type. If the length varies, .NullTerminated or .Undefined is used.
public enum BSONLength {
    /// Used when you're not sure what the length of the BSON byte array is
    case Undefined
    /// Used when you know the exact length of the byte array
    case Fixed(length: Int)
    /// Used when the variable is null-terminated
    case NullTerminated
}

/// This protocol is used for printing the debugger description of a Document
public protocol BSONDebugStringConvertible {
    /// Return a representation of `self` that is (if possible) valid Swift code.
    var bsonDescription: String { get }
}