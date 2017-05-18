//
//  Interpreting.swift
//  BSON
//
//  Created by Robbert Brandsma on 13-02-17.
//
//

import Foundation

extension Document {
    public init?(_ value: Primitive?) {
        if let value = value as? Document {
            self = value
            return
        }
        
        if let dict = value as? [String: Primitive] {
            self = Document(data: dict.makeBinary())
            return
        }
        
        if let array = value as? [Primitive] {
            self = Document(data: array.makeBinary())
            return
        }
        
        return nil
    }
}

extension Timestamp {
    public init?(_ value: Primitive?) {
        guard let value = value as? Timestamp else {
            return nil
        }
        
        self = value
    }
}

extension JavascriptCode {
    public init?(_ value: Primitive?) {
        guard let value = value as? JavascriptCode else {
            return nil
        }
        
        self = value
    }
}

extension Int {
    public init?(_ value: Primitive?) {
        switch value {
        case let val as Int32:
            self = Int(val)
        case let val as Int:
            self = val
        case let val as Double:
            self = Int(val)
        case let val as String:
            if let parsed = Int(val) {
                self = parsed
            } else {
                return nil
            }
        default:
            return nil
        }
    }
}

extension Int32 {
    public init?(_ value: Primitive?) {
        switch value {
        case let val as Int32:
            self = val
        case let val as Int:
            self = Int32(val)
        case let val as Double:
            self = Int32(val)
        case let val as String:
            if let parsed = Int32(val) {
                self = parsed
            } else {
                return nil
            }
        default:
            return nil
        }
    }
}

extension Double {
    public init?(_ value: Primitive?) {
        switch value {
        case let val as Double:
            self = val
        case let val as Int:
            self = Double(val)
        case let val as Int32:
            self = Double(val)
        case let val as String:
            if let parsed = Double(val) {
                self = parsed
            } else {
                return nil
            }
        default:
            return nil
        }
    }
}

extension String {
    public init?(_ value: Primitive?) {
        switch value {
        case let val as String:
            self = val
        case let val as Int:
            self = String(val)
        case let val as Int32:
            self = String(val)
        case let val as ObjectId:
            self = val.hexString
        case let val as Bool:
            self = val ? "true" : "false"
        default:
            return nil
        }
    }
}

extension Bool {
    public init?(_ value: Primitive?) {
        guard let bool = value as? Bool else {
            return nil
        }
        
        self = bool
    }
}

extension Binary {
    public init?(_ value: Primitive?) {
        guard let binary = value as? Binary else {
            return nil
        }
        
        self = binary
    }
}

extension Data {
    public init?(_ value: Primitive?) {
        guard let data = (value as? Binary)?.data else {
            return nil
        }
        
        self = data
    }
}

extension RegularExpression {
    public init?(_ value: Primitive?) {
        guard let regex = value as? RegularExpression else {
            return nil
        }
        
        self = regex
    }
}

extension ObjectId {
    public init?(_ value: Primitive?) {
        guard let objectId = value as? ObjectId else {
            return nil
        }
        
        self = objectId
    }
}

extension Date {
    public init?(_ value: Primitive?) {
        guard let date = value as? Date else {
            return nil
        }
        
        self = date
    }
}

extension Array where Element == Primitive {
    public init?(_ value: Primitive?) {
        guard let document = value as? Document else {
            return nil
        }
        
        self = document.arrayValue
    }
}

extension Dictionary where Key == String, Value == Primitive {
    public init?(_ value: Primitive?) {
        guard let document = value as? Document else {
            return nil
        }
        
        self = document.dictionaryValue
    }
}
