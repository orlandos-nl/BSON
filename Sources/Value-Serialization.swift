//
//  Value-Serialization.swift
//  BSON
//
//  Created by Robbert Brandsma on 18-04-16.
//
//

import Foundation

extension Value {
    public var bsonData : [UInt8] {
        switch self {
        case double(var value):
            return withUnsafePointer(&value) {
                Array(UnsafeBufferPointer(start: UnsafePointer<UInt8>($0), count: sizeof(Double)))
            }
        case string(let value):
            var byteArray = Value.int32(value.utf8.count + 1).bsonData
            byteArray.append(contentsOf: value.utf8)
            byteArray.append(0x00)
            return byteArray
        case document(let value):
            return value.bsonData
        case array(let value):
            return value.bsonData
        case binary(let subtype, let data):
            guard data.count < Int(Int32.max) else {
                return Int32(0).bsonData + [0]
            }
            
            let length = Int32(data.count)
            return length.bsonData + [subtype.rawValue] + data
        case objectId(let value):
            return value.bsonData
        case boolean(let value):
            return value ? [0x01] : [0x00]
        case dateTime(let value):
            var integer = Int64(value.timeIntervalSince1970 * 1000)
            return withUnsafePointer(&integer) {
                Array(UnsafeBufferPointer(start: UnsafePointer<UInt8>($0), count: sizeof(Int64)))
            }
        case regularExpression(let pattern, let options):
            return pattern.cStringBsonData + options.cStringBsonData
        case javascriptCode(let code):
            return code.bsonData
        case .javascriptCodeWithScope(let code, let scope):
            // Scope:
            // code_w_s ::=	int32 string document
            // Code w/ scope - The int32 is the length in bytes of the entire code_w_s value. The string is JavaScript code. The document is a mapping from identifiers to values, representing the scope in which the string should be evaluated.
            let data = code.bsonData + scope.bsonData
            return Int32(data.count+4).bsonData + data
        case int32(var value):
            return withUnsafePointer(&value) {
                Array(UnsafeBufferPointer(start: UnsafePointer<UInt8>($0), count: sizeof(Int32)))
            }
        case timestamp(var value):
            return withUnsafePointer(&value) {
                Array(UnsafeBufferPointer(start: UnsafePointer<UInt8>($0), count: sizeof(Int64)))
            }
        case int64(var value):
            return withUnsafePointer(&value) {
                Array(UnsafeBufferPointer(start: UnsafePointer<UInt8>($0), count: sizeof(Int64)))
            }
        case null, minKey, maxKey, nothing:
            return []
        }
    }
}