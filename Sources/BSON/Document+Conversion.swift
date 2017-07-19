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
        // top level scan
        index(recursive: nil, lookingFor: nil, levels: 0)
        
        return searchTree.storage.count
    }
    
    /// The amount of `Byte`s in the `Document`
    public var byteCount: Int {
        return bytes.count
    }
    
    /// The `Byte` `Array` (`[Byte]`) representation of this `Document`
    public var bytes: Bytes {
        return makeDocumentLength() + storage + [0x00]
    }
    
    /// A list of all keys
    public var keys: [String] {
        var array = [String]()
        
        var position = 0
        
        while position < storage.count {
            guard position &+ 2 < self.storage.count else {
                return array
            }
            
            guard let type = ElementType(rawValue: self.storage[position]) else {
                return array
            }
            
            var buffer = Bytes()
            
            keySkipper : for i in position + 1..<storage.count {
                guard self.storage[i] != 0 else {
                    // null terminator + length
                    position = i &+ 1
                    break keySkipper
                }
                
                buffer.append(self.storage[i])
            }
            
            guard let key = String(bytes: buffer, encoding: .utf8) else {
                return array
            }
            
            array.append(key)
            
            let len = self.getLengthOfElement(withDataPosition: position, type: type)
            
            guard len >= 0 else {
                return array
            }
            
            position = position &+ len
        }
        
        return array
    }
    
    /// The `Dictionary` representation of this `Document`
    public var dictionaryRepresentation: [String: Primitive] {
        var dictionary = [String: Primitive]()
        
        for pos in makeKeyIterator() {
            if let key = String(bytes: pos.keyData[0..<pos.keyData.endIndex], encoding: String.Encoding.utf8) {
                
                let value = getValue(atDataPosition: pos.dataPosition, withType: pos.type)
                
                dictionary[key] = value
            }
        }
        
        return dictionary
    }
    
    /// The `Array` representation of this `Document`
    @available(*, deprecated, renamed: "arrayRepresentation")
    public var arrayValue: [Primitive] {
        return self.arrayRepresentation
    }
    
    /// The `Array` representation of this `Document`.
    /// Returns all values as an array, discarding the keys.
    public var arrayRepresentation: [Primitive] {
        var array = [Primitive]()
        
        var position = 0
        
        while position < storage.count {
            guard position &+ 2 < self.storage.count else {
                return array
            }
            
            guard let type = ElementType(rawValue: self.storage[position]) else {
                return array
            }
            
            keySkipper : for i in position + 1..<storage.count {
                guard self.storage[i] != 0 else {
                    // null terminator + length
                    position = i &+ 1
                    break keySkipper
                }
            }
            
            guard let value = getValue(atDataPosition: position, withType: type) else {
                return array
            }
            
            array.append(value)
            
            let len = self.getLengthOfElement(withDataPosition: position, type: type)
            
            guard len >= 0 else {
                return array
            }
            
            position = position &+ len
        }
        
        return array
    }
    
    /// - returns: `true` when this `Document` is a valid BSON `Array`. `false` otherwise
    public func validatesAsArray() -> Bool {
        if isArray == false {
            return false
        }
        
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

