//
//  JavaScriptCode.swift
//  BSON
//
//  Created by Robbert Brandsma on 03-02-16.
//  Copyright © 2016 Robbert Brandsma. All rights reserved.
//

import Foundation

/// BSON spec type 0x0D: "JavaScript code" or 0x0F: "JavaScript code w/ scope"
public struct JavaScriptCode {
    /// The code stored in this instance.
    public var code: String
    
    /// Optional. Setting the scope will store this JavaScriptCode as type 0x0F: "JavaScript code w/ scope".
    ///
    /// The document is a mapping from identifiers to values, representing the scope in which the string should be evaluated.
    public var scope: Document?
    
    /// Create a new JavaScriptCode instance with given code and (optionally) scope.
    public init(code: String, scope: Document? = nil) {
        self.code = code
        self.scope = scope
    }
}

extension JavaScriptCode : BSONElement {
    /// The ElementType of JavaScriptCode is .JavaScriptCode when it does not define scope or .JavascriptCodeWithScope when it does.
    public var elementType: ElementType {
        return scope == nil ? .JavaScriptCode : .JavascriptCodeWithScope
    }
    
    /// Convert this JavaScriptCode to BSON data ready for storage.
    public var bsonData: [UInt8] {
        if let scope = scope {
            // Scope:
            // code_w_s ::=	int32 string document
            // Code w/ scope - The int32 is the length in bytes of the entire code_w_s value. The string is JavaScript code. The document is a mapping from identifiers to values, representing the scope in which the string should be evaluated.
            let data = code.bsonData + scope.bsonData
            return Int32(data.count+4).bsonData + data
        }
        
        // No scope:
        return code.bsonData
    }
    
    /// .Undefined
    public static let bsonLength = BSONLength.Undefined
    
    /// Not possible, because the JavaScriptCode initializer needs to know it's type. Always throws a `DeserializationError.InvalidOperation`.
    public static func instantiate(bsonData data: [UInt8]) throws -> JavaScriptCode {
        throw DeserializationError.InvalidOperation
    }
    
    /// Instantiate JavaScriptCode from the given data. Behavior depends on the given `type`.
    ///
    /// - param type: If the given data contains scope, this should be .JavascriptCodeWithScope. Otherwise it should be .JavaScriptCode.
    public static func instantiate(bsonData data: [UInt8], inout consumedBytes: Int, type: ElementType) throws -> JavaScriptCode {
        switch type {
        case .JavaScriptCode:
            return self.init(code: try String.instantiate(bsonData: data, consumedBytes: &consumedBytes, type: .String))
        case .JavascriptCodeWithScope:
            // min length is 14 bytes: 4 for the int32, 5 for the string and 5 for the document
            guard data.count >= 14 else {
                throw DeserializationError.InvalidElementSize
            }
            
            // why did they include this? it's not needed. whatever. we'll validate it.
            let totalLength = Int(try Int32.instantiate(bsonData: Array(data[0...3])))
            guard data.count >= totalLength else {
                throw DeserializationError.InvalidElementSize
            }
            
            let stringDataAndMore = Array(data[4..<data.endIndex])
            var trueCodeSize = 0
            let code = try String.instantiate(bsonData: stringDataAndMore, consumedBytes: &trueCodeSize, type: .String)
            
            // - 4 (length) - 5 (document)
            guard data.count - 4 - 5 >= trueCodeSize else {
                throw DeserializationError.InvalidElementSize
            }
            
            let scopeDataAndMaybeMore = Array(data[4+trueCodeSize..<data.endIndex])
            var trueScopeSize = 0
            let scope = try Document.instantiate(bsonData: scopeDataAndMaybeMore, consumedBytes: &trueScopeSize, type: .Document)
            
            // Validation, yay!
            guard totalLength == 4 + trueCodeSize + trueScopeSize else {
                throw DeserializationError.InvalidElementSize
            }
            
            consumedBytes = 4 + trueCodeSize + trueScopeSize
            
            return self.init(code: code, scope: scope)
        default:
            throw DeserializationError.InvalidOperation
        }
    }
    
    public var bsonDescription: String {
        if let scope = scope {
            return "JavaScriptCode(code: \(code.bsonDescription), scope: \(scope.bsonDescription))"
        } else {
            return "JavaScriptCode(code: \(code.bsonDescription))"
        }
    }
}