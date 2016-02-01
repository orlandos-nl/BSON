//
//  Element.swift
//  BSON
//
//  Created by Robbert Brandsma on 23-01-16.
//  Copyright © 2016 Robbert Brandsma. All rights reserved.
//

import Foundation

#if os(Linux)
    import Glibc
#endif

public protocol AbstractBSONBase {}

/// All BSON Element types
public enum ElementType : UInt8 {
    /// This number repesents that the type is a Double
    case Double = 0x01
    /// This number represents that the type is an UTF8 String
    case String = 0x02
    /// This number repesents that the type is a Document or Dictionary
    case Document = 0x03
    /// This number repesents that the type is an array
    case Array = 0x04
    /// This number repesents that the type is a binary array
    case Binary = 0x05
    /// This number repesents that the type is an objectID
    case ObjectId = 0x07
    /// This number repesents that the type is a boolean
    case Boolean = 0x08
    /// This number repesents that the type is a datetime value
    case DateTime = 0x09
    /// This number repesents that the type is null (no value)
    case NullValue = 0x0A
    /// This number repesents that the type is a regex
    case RegularExpression = 0x0B
    /// This number repesents that the type is JavaScript Code
    case JavaScriptCode = 0x0D
    /// This number repesents that the type is JavaScript code without a scope
    case JavascriptCodeWithScope = 0x0F
    /// This number repesents that the type is an 32-bit integer
    case Int32 = 0x10
    /// This number repesents that the type is a timestamp
    case Timestamp = 0x11
    /// This number repesents that the type is an 32-bit integer
    case Int64 = 0x12
    /// This number repesents that the type is a BSON min-key
    case MinKey = 0xFF
    /// This number repesents that the type is a BSON max-key
    case MaxKey = 0x7F
}

extension ElementType {
    /// The native swift type for the current type
    var type: BSONElementConvertible.Type {
        switch self {
        case .Double:
            return Swift.Double.self
        case .String:
            return Swift.String.self
        case .Document:
            return BSON.Document.self
        case .Array:
            return BSON.Document.self
        case .Binary:
            abort()
        case .ObjectId:
            return BSON.ObjectId.self
        case .Boolean:
            return Swift.Bool.self
        case .DateTime:
            return Foundation.NSDate.self
        case .NullValue:
            return BSON.Null.self
        case .RegularExpression:
            abort()
        case .JavaScriptCode:
            abort()
        case .JavascriptCodeWithScope:
            abort()
        case .Int32:
            return Swift.Int32.self
        case .Timestamp:
            abort()
        case .Int64:
            return Swift.Int.self
        case .MinKey:
            abort()
        case .MaxKey:
            abort()
        }
    }
}

/// Represents the length of a BSON type
public enum BsonLength {
    /// Used when you're not sure what the length of the BSON byte array is
    case Undefined
    /// Used when you know the exact length of the byte array
    case Fixed(length: Int)
    /// Used when the variable is null-terminated
    case NullTerminated
}

/// Anything complying to the protocol is conertible from- and to BSON Binary
public protocol BSONElementConvertible : AbstractBSONBase {
    var elementType: ElementType { get }
    
    /// Here, return the same data as you would accept in the initializer
    var bsonData: [UInt8] { get }
    
    /// The length of this variable when converted to an Array of UInt8
    static var bsonLength: BsonLength { get }
    
    /// The initializer expects the data for this element, starting AFTER the element type
    /// The input consumedBytes is set the the amount of bytes we consumed instantiating this variable
    static func instantiate(bsonData data: [UInt8], inout consumedBytes: Int) throws -> Self
    
    /// The initializer expects the data for this element, starting AFTER the element type
    static func instantiate(bsonData data: [UInt8]) throws -> Self
}