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
    var type: BSONElement.Type {
        switch self {
        case .Double:
            return Swift.Double.self
        case .String:
            return Swift.String.self
        case .Document, .Array:
            return BSON.Document.self
        case .Binary:
            return BSON.Binary.self
        case .ObjectId:
            return BSON.ObjectId.self
        case .Boolean:
            return Swift.Bool.self
        case .DateTime:
            return Foundation.NSDate.self
        case .NullValue:
            return BSON.Null.self
        case .RegularExpression:
            return BSON.RegularExpression.self
        case .JavaScriptCode, .JavascriptCodeWithScope:
            return BSON.JavaScriptCode.self
        case .Int32:
            return Swift.Int32.self
        case .Timestamp:
            return BSON.Timestamp.self
        case .Int64:
            return Swift.Int.self
        case .MinKey:
            return BSON.MinKey.self
        case .MaxKey:
            return BSON.MaxKey.self
        }
    }
}

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

/// Anything complying to the protocol is convertible from- and to BSON Binary
public protocol BSONElement : BSONDebugStringConvertible {
    /// Identifies the BSON element type, such as `.String` (0x02)
    var elementType: ElementType { get }
    
    /// Here, return the same data as you would accept in the initializer
    var bsonData: [UInt8] { get }
    
    /// The length of this variable when converted to an array of `UInt8`
    static var bsonLength: BSONLength { get }
    
    /// The initializer expects the data for this element, starting AFTER the element type
    /// The input consumedBytes is set the the amount of bytes we consumed instantiating this variable
    /// Objects that support initialization from only one `ElementType` may ignore this parameter.
    static func instantiate(bsonData data: [UInt8], inout consumedBytes: Int, type: ElementType) throws -> Self
    
    /// The initializer expects the data for this element, starting AFTER the element type
    static func instantiate(bsonData data: [UInt8]) throws -> Self
}

public extension BSONElement {
    /// Returns the value of `self` interpeted as an Int. Will return a value if `self` is of one of the following types:
    /// Float, Double, Int16, Int32, Int64, Int
    public var intValue: Int? {
        typealias Beauty = Int
        switch self {
        case let me as Float: return Beauty(me)
        case let me as Double: return Beauty(me)
        case let me as Int16: return Beauty(me)
        case let me as Int32: return Beauty(me)
        case let me as Int64: return Beauty(me)
        case let me as Int: return Beauty(me)
        default: return nil
        }
    }
    
    /// Returns the value of `self` interpeted as an Int64. Will return a value if `self` is of one of the following types:
    /// Float, Double, Int16, Int32, Int64, Int
    public var int64Value: Int64? {
        typealias Beauty = Int64
        switch self {
        case let me as Float: return Beauty(me)
        case let me as Double: return Beauty(me)
        case let me as Int16: return Beauty(me)
        case let me as Int32: return Beauty(me)
        case let me as Int64: return Beauty(me)
        case let me as Int: return Beauty(me)
        default: return nil
        }
    }
    
    /// Returns the value of `self` interpeted as an Int32. Will return a value if `self` is of one of the following types:
    /// Float, Double, Int16, Int32, Int64, Int
    public var int32Value: Int32? {
        typealias Beauty = Int32
        switch self {
        case let me as Float: return Beauty(me)
        case let me as Double: return Beauty(me)
        case let me as Int16: return Beauty(me)
        case let me as Int32: return Beauty(me)
        case let me as Int64: return Beauty(me)
        case let me as Int: return Beauty(me)
        default: return nil
        }
    }
    
    /// Returns the value of `self` interpeted as a Double. Will return a value if `self` is of one of the following types:
    /// Float, Double, Int16, Int32, Int64, Int
    public var doubleValue: Double? {
        typealias Beauty = Double
        switch self {
        case let me as Float: return Beauty(me)
        case let me as Double: return Beauty(me)
        case let me as Int16: return Beauty(me)
        case let me as Int32: return Beauty(me)
        case let me as Int64: return Beauty(me)
        case let me as Int: return Beauty(me)
        default: return nil
        }
    }
    
    /// Returns `self` if self is a `String`
    public var stringValue: String? {
        return self as? String
    }
    
    /// Returns `self` if self is a `NSDate`
    public var dateValue: NSDate? {
        return self as? NSDate
    }
    
    /// Returns `self` if self is a `RegularExpression`
    public var regularExpressionValue: RegularExpression? {
        return self as? RegularExpression
    }
    
    /// Returns `self` if self is `JavaScriptCode`
    public var javaScriptCodeValue: JavaScriptCode? {
        return self as? JavaScriptCode
    }
    
    /// Returns `self` if self is `Binary`
    public var binaryValue: Binary? {
        return self as? Binary
    }
    
    /// Returns `self` if self is `ObjectId`
    public var objectIdValue: ObjectId? {
        return self as? ObjectId
    }
    
    /// Returns `self` if self is `Timestamp`
    public var timestampValue: Timestamp? {
        return self as? Timestamp
    }
    
    /// Returns `self` if self is `Null`
    public var nullValue: Null? {
        return self as? Null
    }
    
    /// Returns `self` if self is `Document`
    public var documentValue: Document? {
        return self as? Document
    }
}

public extension BSONElement {
    public subscript(key: String) -> BSONElement? {
        if let me = self as? Document {
            return me[key]
        } else {
            return nil
        }
    }
    
    public subscript(key: Int) -> BSONElement? {
        if let me = self as? Document {
            return me[key]
        } else {
            return nil
        }
    }
}

/// Currently only supports Double, String, and Integer
// TODO: Add more data types to compare here
public func ==(left: BSONElement, right: BSONElement) -> Bool {
    switch (left.elementType, right.elementType) {
    case (.Double, .Double):
        return left.doubleValue == right.doubleValue
    case (.String, .String):
        return left.stringValue == right.stringValue
    case (.Int32, .Int32), (.Int64, .Int64):
        return left.int64Value == right.int64Value
    default:
        return false
    }
}

// needed because we cannot make BSONElement equateable
public func !=(left: BSONElement, right: BSONElement) -> Bool {
    return !(left == right)
}