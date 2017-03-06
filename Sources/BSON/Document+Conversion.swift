//
//  Document+ConversionMetadata.swift
//  BSON
//
//  Created by Robbert Brandsma on 17-08-16.
//
//

import Foundation
import KittenCore

extension Document {
    /// The amount of key-value pairs in the `Document`
    public var count: Int {
        return searchTree.count
    }
    
    /// The amount of `Byte`s in the `Document`
    public var byteCount: Int {
        return bytes.count
    }
    
    /// The `Byte` `Array` (`[Byte]`) representation of this `Document`
    public var bytes: Bytes {
        return storage + [0x00]
    }
    
    /// A list of all keys
    public var keys: [String] {
        return searchTree.sorted { lhs, rhs in
            return lhs.1 < rhs.1
            }.flatMap {String(bytes: $0.0.bytes, encoding: .utf8)}
    }
    
    public var efficientKeyValuePairs: [(KittenBytes, Primitive)] {
        var pairs = [(KittenBytes, Primitive)]()
        
        for pos in makeKeyIterator() {
            let key = KittenBytes(Array(pos.keyData[0..<pos.keyData.endIndex-1]))
            
            if let value = getValue(atDataPosition: pos.dataPosition, withType: pos.type, kittenString: true) {
                pairs.append((key, value))
            }
        }
        
        return pairs
    }
    
    /// The `Dictionary` representation of this `Document`
    public var dictionaryValue: [String: Primitive] {
        var dictionary = [String: Primitive]()
        
        for pos in makeKeyIterator() {
            if let key = String(bytes: pos.keyData[0..<pos.keyData.endIndex-1], encoding: String.Encoding.utf8) {
                
                let value = getValue(atDataPosition: pos.dataPosition, withType: pos.type)
                
                dictionary[key] = value
            }
        }
        
        return dictionary
    }
    
    /// The `Array` representation of this `Document`
    public var arrayValue: [Primitive] {
        return makeKeyIterator().flatMap { pos in
            getValue(atDataPosition: pos.dataPosition, withType: pos.type)
        }
    }
    
    /// - returns: `true` when this `Document` is a valid BSON `Array`. `false` otherwise
    public func validatesAsArray() -> Bool {
        for key in self.makeKeyIterator() {
            for byte in key.keyData {
                guard (byte >= 48 && byte <= 57) || byte == 0x00 else {
                    return false
                }
            }
        }
        
        return true
    }
}

