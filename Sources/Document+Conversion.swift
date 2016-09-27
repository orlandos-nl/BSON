//
//  Document+ConversionMetadata.swift
//  BSON
//
//  Created by Robbert Brandsma on 17-08-16.
//
//

import Foundation

extension Document {
    /// The amount of key-value pairs in the `Document`
    public var count: Int {
        return elementPositions.count
    }
    
    /// The amount of `Byte`s in the `Document`
    public var byteCount: Int {
        return bytes.count
    }
    
    /// The `Byte` `Array` (`[Byte]`) representation of this `Document`
    public var bytes: [UInt8] {
        return storage + [0x00]
    }
    
    /// A list of all keys
    public var keys: [String] {
        var keys = [String]()
        for element in self.makeKeyIterator() {
            guard let key = try? String.instantiateFromCString(bytes: element.keyData) else {
                // huh?
                // TODO: Make that init nonfailing.
                continue
            }
            
            keys.append(key)
        }
        return keys
    }
    
    /// The `Dictionary` representation of this `Document`
    public var dictionaryValue: [String: Value] {
        var dictionary = [String: Value]()
        
        for pos in makeKeyIterator() {
            if let key = String(bytes: pos.keyData[0..<pos.keyData.endIndex-1], encoding: String.Encoding.utf8) {
                
                let value = getValue(atDataPosition: pos.dataPosition, withType: pos.type)
                
                dictionary[key] = value
            }
        }
        
        return dictionary
    }
    
    /// The `Array` representation of this `Document`
    public var arrayValue: [Value] {
        var array = [Value]()
        
        for pos in makeKeyIterator() {
            let value = getValue(atDataPosition: pos.dataPosition, withType: pos.type)
            
            array.append(value)
        }
        
        return array
    }
    
    /// - returns: `true` when this `Document` is a valid BSON `Array`. `false` otherwise
    public func validatesAsArray() -> Bool {
        var index = 0
        
        for key in self.keys {
            guard key == String(index) else {
                return false
            }
            
            index += 1
        }
        
        return true
    }
}
    
