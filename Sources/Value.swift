//
//  Value.swift
//  BSON
//
//  Created by Robbert Brandsma on 18-04-16.
//
//

import Foundation

public enum BinarySubtype {
    case generic, function, binaryOld, uuidOld, uuid, md5, userDefined(UInt8)
    
    public var rawValue : UInt8 {
        switch self {
        case generic: return 0x00
        case function: return 0x01
        case binaryOld: return 0x02
        case uuidOld: return 0x03
        case uuid: return 0x04
        case md5: return 0x05
        case userDefined(let value): return value
        }
    }
    
    public init(rawValue: UInt8) {
        switch rawValue {
        case 0x00: self = .generic
        case 0x01: self = .function
        case 0x02: self = .binaryOld
        case 0x03: self = .uuidOld
        case 0x04: self = .uuid
        case 0x05: self = .md5
        default: self = .userDefined(rawValue)
        }
    }
}

public enum Value {
    case double(Double)
    case string(String)
    case document(Document)
    case array(Document)
    case binary(subtype: BinarySubtype, data: [UInt8])
    case objectId(ObjectId)
    case boolean(Bool)
    case dateTime(Date)
    case null
    case regularExpression(pattern: String, options: String)
    case javascriptCode(String)
    case javascriptCodeWithScope(code: String, scope: Document)
    case int32(Int32)
    case timestamp(stamp: Int32, increment: Int32)
    case int64(Int64)
    case minKey
    case maxKey
    case nothing
    
    internal var typeIdentifier : UInt8 {
        switch self {
        case double: return 0x01
        case string: return 0x02
        case document: return 0x03
        case array: return 0x04
        case binary: return 0x05
        case objectId: return 0x07
        case boolean: return 0x08
        case dateTime: return 0x09
        case null: return 0x0A
        case regularExpression: return 0x0B
        case javascriptCode: return 0x0D
        case javascriptCodeWithScope: return 0x0F
        case int32: return 0x10
        case timestamp: return 0x11
        case int64: return 0x12
        case minKey: return 0xFF
        case maxKey: return 0x7F
        case nothing: return 0x0A
        }
    }
}
