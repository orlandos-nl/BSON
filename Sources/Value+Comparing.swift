//
//  Value+Comparing.swift
//  BSON
//
//  Created by Robbert Brandsma on 18-04-16.
//
//

import Foundation

extension Value : Equatable {}

public func ==(lhs: Value, rhs: Value) -> Bool {
    switch (lhs, rhs) {
    case (.double(_), _):
        return lhs.double == rhs.doubleValue
    case (.string(_), _):
        return lhs.string == rhs.stringValue
    case (.document(_), _), (.array(_), _):
        return lhs.document == rhs.documentValue && lhs.document.isArray == rhs.documentValue?.isArray
    case (.binary(let subtype1, let data1), .binary(let subtype2, let data2)):
        return subtype1.rawValue == subtype2.rawValue && data1 == data2
    case (.objectId(_), .objectId(_)):
        return lhs.bytes == rhs.bytes
    case (.boolean(let val1), .boolean(let val2)):
        return val1 == val2
    case (.dateTime(let val1), .dateTime(let val2)):
        return val1 == val2
    case (.regularExpression(let exp1, let opt1), .regularExpression(let exp2, let opt2)):
        return exp1 == exp2 && opt1 == opt2
    case (.javascriptCode(let code1), .javascriptCode(let code2)):
        return code1 == code2
    case (.javascriptCodeWithScope(let code1, let scope1), .javascriptCodeWithScope(let code2, let scope2)):
        return code1 == code2 && scope1 == scope2
    case (.int32(_), _):
        return lhs.int32 == rhs.int32Value
    case (.timestamp(let val1), .timestamp(let val2)):
        return val1 == val2
    case (.int64(_), _):
        return lhs.int64 == rhs.int64Value
    case (.minKey, .minKey), (.maxKey, .maxKey), (.null, .null), (.nothing, .nothing):
        return true
    default:
        return false
    }
}

public func ==(lhs: Value, rhs: String) -> Bool {
    return lhs.string == rhs
}

public func ==(lhs: Value, rhs: Int) -> Bool {
    return lhs.int == rhs
}

public func ==(lhs: Value, rhs: Int32) -> Bool {
    return lhs.int32 == rhs
}

public func ==(lhs: Value, rhs: Int64) -> Bool {
    return lhs.int64 == rhs
}

public func ==(lhs: Value, rhs: [UInt8]) -> Bool {
    guard case .binary(_, let bytes) = lhs else {
        return false
    }
    
    return bytes == rhs
}

public func ==(lhs: Value, rhs: [Value]) -> Bool {
    guard case .array(let document) = lhs, document.validatesAsArray(), document.isArray else {
        return false
    }
    
    return document.arrayValue == rhs
}

public func ==(lhs: Value, rhs: Document) -> Bool {
    if case .document(let document) = lhs {
        return document == rhs
    } else if case .array(let array) = lhs {
        return array == rhs
    } else {
        return false
    }
}

public func ==(lhs: Value, rhs: [String: Value]) -> Bool {
    guard case .document(let document) = lhs else {
        return false
    }
    
    return document.dictionaryValue == rhs
}

public func ==(lhs: Value, rhs: Bool) -> Bool {
    return lhs.boolValue == rhs
}

public func ==(lhs: Value, rhs: Double) -> Bool {
    return lhs.double == rhs
}

public func ==(lhs: Value, rhs: Date) -> Bool {
    guard case .dateTime(let date) = lhs else {
        return false
    }
    
    return date == rhs
}

public func ==(lhs: ObjectId, rhs: ObjectId) -> Bool {
    return lhs._storage == rhs._storage
}

public func ==(lhs: Value, rhs: ObjectId) -> Bool {
    guard let lhs = lhs.objectIdValue else {
        return false
    }
    
    return lhs == rhs
}

public func ==(lhs: String, rhs: ObjectId) -> Bool {
    return lhs.lowercased() == rhs.hexString.lowercased()
}

public func ==(lhs: ObjectId, rhs: String) -> Bool {
    return lhs.hexString.lowercased() == rhs.lowercased()
}

public func ===(lhs: Value, rhs: Value) -> Bool {
    switch (lhs, rhs) {
    case (.double(_), .double(_)), (.string(_), .string(_)), (.document(_), .document(_)), (.array(_), .array(_)), (.binary(_), .binary(_)), (.objectId(_), .objectId(_)), (.boolean(_), .boolean(_)), (.dateTime(_), .dateTime(_)), (.regularExpression(_, _), .regularExpression(_, _)), (.javascriptCode(_), .javascriptCode(_)), (.javascriptCodeWithScope(_, _), .javascriptCodeWithScope(_, _)), (.int32(_), .int32(_)), (.timestamp(_), .timestamp(_)), (.int64(_), .int64(_)), (.minKey, .minKey), (.maxKey, .maxKey), (.null, .null), (.nothing, .nothing):
        return lhs.typeIdentifier == rhs.typeIdentifier && lhs.bytes == rhs.bytes
    default:
        return false
    }
}
