//
//  Value-Extraction.swift
//  BSON
//
//  Created by Robbert Brandsma on 18-04-16.
//
//

import Foundation

extension ValueConvertible {
    /// Returns this value interpeted as a `Double`.
    /// This works for values of the following types:
    ///
    /// - Double
    /// - String
    /// - Boolean
    /// - DateTime - will be converted to seconds since the Unix Epoch
    /// - Int32
    /// - Int64
    /// - Timestamp
    ///
    /// If the value cannot be interpeted as a `Double`, Double(0) will be returned.
    public var double : Double {
        switch self.makeBsonValue() {
        case .double(let val): return val
        case .string(let val): return Double(val) ?? 0
        case .boolean(let val): return val ? 1 : 0
        case .dateTime(let val): return val.timeIntervalSince1970
        case .int32(let val): return Double(val)
        case .int64(let val): return Double(val)
        default: return 0
        }
    }
    
    /// Returns this value interpeted as a `String`.
    /// This works for values of the following types:
    ///
    /// - String
    /// - Double
    /// - Boolean
    /// - DateTime - will be converted to seconds sinds the Unix Epoch
    /// - Int32
    /// - Int64
    /// - ObjectId
    /// - Timestamp
    ///
    /// If the value cannot be interpeted as a `Double`, Double(0) will be returned.
    public var string : String {
        switch self.makeBsonValue() {
        case .double(let val): return "\(val)"
        case .string(let val): return val
        case .objectId(let val): return val.hexString
        case .boolean(let val): return val ? "true" : "false"
        case .dateTime(let val): return "\(val.timeIntervalSince1970)"
        case .int32(let val): return "\(val)"
        case .timestamp(let val): return "\(val)"
        case .int64(let val): return "\(val)"
        default: return ""
        }
    }
    
    /// Returns the contained document if `self` is `array` or `document`. If self is not `array` or `document`, an empty `Document` will be returned.
    public var document : Document {
        switch self.makeBsonValue() {
        case .array(let val): return val
        case .document(let val): return val
        default: return [:]
        }
    }
    
    /// Returns this value interpeted as a `Bool`.
    /// This works for values of the following types:
    ///
    /// - Double
    /// - String
    /// - Boolean
    /// - Int32
    /// - Int64
    ///
    /// If the value cannot be interpeted as a `Double`, Double(0) will be returned.
    public var bool : Bool {
        switch self.makeBsonValue() {
        case .double(let val): return val == 0 ? false : true
        case .string(let val): return val == "true" ? true : false
        case .boolean(let val): return val
        case .int32(let val): return val == 0 ? false : true
        case .int64(let val): return val == 0 ? false : true
        default: return false
        }
    }
    
    /// Returns this value interpeted as a `Int64`.
    /// This works for values of the following types:
    ///
    /// - Double
    /// - String
    /// - Boolean
    /// - DateTime - will be converted to milliseconds sinds the Unix Epoch
    /// - Int32
    /// - Int64
    /// - Timestamp
    ///
    /// If the value cannot be interpeted as a `Int64`, Int64(0) will be returned.
    public var int64 : Int64 {
        switch self.makeBsonValue() {
        case .double(let val): return Int64(val)
        case .string(let val): return Int64(val) ?? 0
        case .boolean(let val): return val ? 1 : 0
        case .dateTime(let val): return Int64(val.timeIntervalSince1970*1000)
        case .int32(let val): return Int64(val)
        case .int64(let val): return val
        default: return 0
        }
    }
    
    /// Returns this value interpeted as a `Int`.
    /// This works for values of the following types:
    ///
    /// - Double
    /// - String
    /// - Boolean
    /// - DateTime - will be converted to milliseconds sinds the Unix Epoch
    /// - Int32
    /// - Int64
    /// - Timestamp
    ///
    /// If the value cannot be interpeted as a `Int`, Int(0) will be returned.
    public var int : Int {
        return Int(self.int64)
    }
    
    /// Returns this value interpeted as a `Int32`.
    /// This works for values of the following types:
    ///
    /// - Double
    /// - String
    /// - Boolean
    /// - DateTime - will be converted to milliseconds sinds the Unix Epoch
    /// - Int32
    /// - Int64
    /// - Timestamp
    ///
    /// If the value cannot be interpeted as a `Int32`, Int32(0) will be returned.
    public var int32 : Int32 {
        switch self.makeBsonValue() {
        case .double(let val): return Int32(val)
        case .string(let val): return Int32(val) ?? 0
        case .boolean(let val): return val ? 1 : 0
        case .dateTime(let val): return Int32(val.timeIntervalSince1970*1000)
        case .int32(let val): return val
        case .int64(let val): return Int32(val)
        default: return 0
        }
    }
    
    // MARK: ... value
    public var storedValue : Any? {
        switch self.makeBsonValue() {
        case .double(let val): return val
        case .string(let val): return val
        case .document(let val): return val
        case .array(let val): return val
        case .binary(let val): return val
        case .objectId(let val): return val
        case .boolean(let val): return val
        case .dateTime(let val): return val
        case .regularExpression(let val): return val
        case .javascriptCode(let val): return val
        case .javascriptCodeWithScope(let val): return val
        case .int32(let val): return val
        case .timestamp(let val): return val
        case .int64(let val): return val
        case .null, .minKey, .maxKey, .nothing: return nil
        }
    }
    
    /// Returns the raw value only if the underlying value is stored as `Double`. Otherwise, returns `nil`.
    public var doubleValue : Double? {
        return self.storedValue as? Double
    }
    
    /// Returns the raw value only if the underlying value is stored as `String`. Otherwise, returns `nil`.
    public var stringValue : String? {
        return self.storedValue as? String
    }
    
    /// Returns the raw value only if the underlying value is stored as `Document`. Otherwise, returns `nil`.
    public var documentValue : Document? {
        return self.storedValue as? Document
    }
    
    /// Returns the raw value only if the underlying value is stored as `Bool`. Otherwise, returns `nil`.
    public var boolValue : Bool? {
        return self.storedValue as? Bool
    }
    
    /// Returns the raw value only if the underlying value is stored as `Date`. Otherwise, returns `nil`.
    public var dateValue : Date? {
        return self.storedValue as? Date
    }
    
    /// Returns the raw value only if the underlying value is stored as `Int32`. Otherwise, returns `nil`.
    public var int32Value : Int32? {
        return self.storedValue as? Int32
    }
    
    /// Returns the raw value only if the underlying value is stored as `Int64`. Otherwise, returns `nil`.
    public var int64Value : Int64? {
        return self.storedValue as? Int64
    }
    
    /// Returns the raw value only if the underlying value is stored as `ObjectId`. Otherwise, returns `nil`.
    public var objectIdValue : ObjectId? {
        return self.storedValue as? ObjectId
    }
}
