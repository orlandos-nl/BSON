//
//  Value-Serialization.swift
//  BSON
//
//  Created by Robbert Brandsma on 18-04-16.
//
//

import Foundation

extension Value {
    public var bytes: [UInt8] {
        switch self {
        case .double(let value):
            return value.makeBytes()
        case .string(let value):
            var byteArray = Int32(value.utf8.count + 1).makeBytes()
            byteArray.append(contentsOf: value.utf8)
            byteArray.append(0x00)
            return byteArray
        case .document(let value):
            return value.bytes
        case .array(let value):
            return value.bytes
        case .binary(let subtype, let data):
            guard data.count < Int(Int32.max) else {
                // 4 bytes for the length and a null terminator byte
                return [0, 0, 0, 0, 0]
            }
            
            let length = Int32(data.count)
            return length.makeBytes() + [subtype.rawValue] + data
        case .objectId(let id):
            return id._storage
        case .boolean(let value):
            return value ? [0x01] : [0x00]
        case .dateTime(let value):
            let integer = Int(value.timeIntervalSince1970 * 1000)
            return integer.makeBytes()
        case .regularExpression(let pattern, let options):
            return pattern.cStringBytes + options.cStringBytes
        case .javascriptCode(let code):
            return code.bytes
        case .javascriptCodeWithScope(let code, let scope):
            // Scope:
            // code_w_s ::=	int32 string document
            // Code w/ scope - The int32 is the length in bytes of the entire code_w_s value. The string is JavaScript code. The document is a mapping from identifiers to values, representing the scope in which the string should be evaluated.
            let data = code.bytes + scope.bytes
            return Int32(data.count+4).makeBytes() + data
        case .int32(let value):
            return value.makeBytes()
        case .timestamp(let value):
            return value.stamp.makeBytes() + value.increment.makeBytes()
        case .int64(let value):
            return value.makeBytes()
        case .null, .minKey, .maxKey, .nothing:
            return []
        }
    }
}
