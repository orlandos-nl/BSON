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

public enum ElementType : UInt8 {
    case Double = 0x01
    case String = 0x02
    case Document = 0x03
    case Array = 0x04
    case Binary = 0x05
    //  case DeprecatedUndefinedValue = 0x06
    case ObjectId = 0x07
    case Boolean = 0x08
    case DateTime = 0x09
    case NullValue = 0x0A
    case RegularExpression = 0x0B
    //  case DeprecatedDBPointer = 0x0C
    case JavaScriptCode = 0x0D
    //  case Deprecated = 0x0E
    case JavascriptCodeWithScope = 0x0F
    case Int32 = 0x10
    case Timestamp = 0x11
    case Int64 = 0x12
    case MinKey = 0xFF
    case MaxKey = 0x7F
}

extension ElementType {
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
            abort()
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

public enum BsonLength {
    case Undefined
    case Fixed(length: Int)
    case NullTerminated
}

public protocol BSONElementConvertible {
    var elementType: ElementType { get }
    
    /// Here, return the same data as you would accept in the initializer
    var bsonData: [UInt8] { get }
    
    static var bsonLength: BsonLength { get }
    
    /// The initializer expects the data for this element, starting AFTER the element type
    static func instantiate(bsonData data: [UInt8], inout consumedBytes: Int) throws -> Self
    static func instantiate(bsonData data: [UInt8]) throws -> Self
}