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
    public var double : Double? {
        get {
            if let num = self as? Int32 {
                return Double(num)
            } else if let num = self as? Int64 {
                return Double(num)
            } else if let num = self as? Double {
                return Double(num)
            } else if let num = self as? String {
                return Double(num)
            }
            
            return nil
        }
        set {
            if let newValue = newValue as? Self {
                self = newValue
            }
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
    public var string : String? {
        get {
            if let num = self as? Int32 {
                return String(num)
            } else if let num = self as? Int64 {
                return String(num)
            } else if let num = self as? Double {
                return String(num)
            } else if let bool = self as? Bool {
                return bool ? "true" : "false"
            } else if let s = self as? String {
                return s
            } else if let oid = self as? ObjectId {
                return oid.hexString
            }
            
            return nil
        }
        set {
            if let newValue = newValue as? Self {
                self = newValue
            }
        }
    }
    
    public var int64 : Int64? {
        get {
            if let num = self as? Int32 {
                return Int64(num)
            } else if let num = self as? Int64 {
                return Int64(num)
            } else if let num = self as? Double {
                return Int64(num)
            } else if let num = self as? String {
                return Int64(num)
            }
            
            return nil
        }
        set {
            if let newValue = newValue as? Self {
                self = newValue
            }
        }
    }
    
    public var int : Int? {
        get {
            guard let int64 = self.int64 else {
                return nil
            }
            
            return Int(int64)
        }
        set {
            if let newValue = newValue as? Self {
                self = newValue
            }
        }
    }
    
    public var int32 : Int32? {
        get {
            if let num = self as? Int32 {
                return Int32(num)
            } else if let num = self as? Int64 {
                return Int32(num)
            } else if let num = self as? Double {
                return Int32(num)
            } else if let num = self as? String {
                return Int32(num)
            }
            
            return nil
        }
        set {
            if let newValue = newValue as? Self {
                self = newValue
            }
        }
    }
    
    /// Returns the raw value only if the underlying value is stored as `Double`. Otherwise, returns `nil`.
    public var doubleValue : Double? {
        return self as? Double
    }
    
    /// Returns the raw value only if the underlying value is stored as `String`. Otherwise, returns `nil`.
    public var stringValue : String? {
        return self as? String
    }
    
    /// Returns the raw value only if the underlying value is stored as `Document`. Otherwise, returns `nil`.
    public var documentValue : Document? {
        return self as? Document
    }
    
    /// Returns the raw value only if the underlying value is stored as `Bool`. Otherwise, returns `nil`.
    public var boolValue : Bool? {
        return self as? Bool
    }
    
    /// Returns the raw value only if the underlying value is stored as `Date`. Otherwise, returns `nil`.
    public var dateValue : Date? {
        return self as? Date
    }
    
    /// Returns the raw value only if the underlying value is stored as `Int32`. Otherwise, returns `nil`.
    public var int32Value : Int32? {
        return self as? Int32
    }
    
    /// Returns the raw value only if the underlying value is stored as `Int64`. Otherwise, returns `nil`.
    public var int64Value : Int64? {
        return self as? Int64
    }
    
    /// Returns the raw value only if the underlying value is stored as `ObjectId`. Otherwise, returns `nil`.
    public var objectIdValue : ObjectId? {
        return self as? ObjectId
    }
}
