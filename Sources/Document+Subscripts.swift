//
//  Document+Subscripts.swift
//  BSON
//
//  Created by Robbert Brandsma on 17-08-16.
//
//

import Foundation

extension Document {
    /// Mutates the key-value pair like you would with a `Dictionary`
    public subscript(key: String) -> ValueConvertible? {
        get {
            let parts = key.components(separatedBy: ".")
            
            return self[parts]
        }
        
        set {
            let parts = key.components(separatedBy: ".")
            
            self[parts] = newValue
        }
    }
    
    /// Mutates the key-value pair like you would with a `Dictionary`
    public subscript(literal key: String) -> ValueConvertible? {
        get {
            guard let meta = getMeta(forKeyBytes: [UInt8](key.utf8)) else {
                return nil
            }
            
            return getValue(atDataPosition: meta.dataPosition, withType: meta.type)
        }
        
        set {
            let newValue = newValue?.makeBsonValue() ?? .nothing
            
            if let meta = getMeta(forKeyBytes: [UInt8](key.utf8)) {
                let len = getLengthOfElement(withDataPosition: meta.dataPosition, type: meta.type)
                let dataEndPosition = meta.dataPosition+len
                
                storage.removeSubrange(meta.dataPosition..<dataEndPosition)
                storage.insert(contentsOf: newValue.bytes, at: meta.dataPosition)
                storage[meta.elementTypePosition] = newValue.typeIdentifier
                updateDocumentHeader()
                self.elementPositions = buildElementPositionsCache()
                
                return
            }
            
            self.append(newValue, forKey: key)
        }
    }
    
    public subscript(partOne: String, otherParts: String...) -> ValueConvertible? {
        get {
            return self[[partOne] + otherParts]
        }
        set {
            self[[partOne] + otherParts] = newValue
        }
    }
    
    /// Mutates the key-value pair like you would with a `Dictionary`
    public subscript(parts: [String]) -> ValueConvertible? {
        get {
            guard parts.count > 0 else {
                return nil
            }
            
            var parts = parts
            let firstPart = parts.removeFirst()
            
            return parts.count == 0 ? self[literal: firstPart] : self[literal: firstPart]?.documentValue?[parts]
        }
        
        set {
            if parts.count == 1 {
                let newValue = newValue?.makeBsonValue() ?? .nothing
                
                if let meta = getMeta(forKeyBytes: [UInt8](parts[0].utf8)) {
                    let len = getLengthOfElement(withDataPosition: meta.dataPosition, type: meta.type)
                    let dataEndPosition = meta.dataPosition+len
                    
                    storage.removeSubrange(meta.dataPosition..<dataEndPosition)
                    storage.insert(contentsOf: newValue.bytes, at: meta.dataPosition)
                    storage[meta.elementTypePosition] = newValue.typeIdentifier
                    updateDocumentHeader()
                    
                    return
                }
                
                self.append(newValue, forKey: parts[0])
            } else if parts.count >= 2 {
                var parts = parts
                let firstPart = parts.removeFirst()
                
                var doc = self[firstPart]?.documentValue ?? [:]
                doc[parts] = newValue
                
                self[firstPart] = doc
            }
        }
    }
    
    /// Mutates the value store like you would with an `Array`
    public subscript(key: Int) -> ValueConvertible? {
        get {
            if let value = self["\(key)"] {
                return value
            }
            
            var keyPos = 0
            
            for currentKey in makeKeyIterator() {
                if keyPos == key {
                    return getValue(atDataPosition: currentKey.dataPosition, withType: currentKey.type)
                }
                
                keyPos += 1
            }
            
            return nil
        }
        set {
            let newValue = newValue?.makeBsonValue() ?? .nothing
            
            if let currentKey = getMeta(atPosition: elementPositions[key]) {
                let len = getLengthOfElement(withDataPosition: currentKey.dataPosition, type: currentKey.type)
                let dataEndPosition = currentKey.dataPosition+len
                
                storage.removeSubrange(currentKey.dataPosition..<dataEndPosition)
                storage.insert(contentsOf: newValue.bytes, at: currentKey.dataPosition)
                storage[currentKey.startPosition] = newValue.typeIdentifier
                
                let oldLength = dataEndPosition - currentKey.dataPosition
                let relativeLength = newValue.bytes.count - oldLength
                
                for (index, element) in elementPositions.enumerated() where element > currentKey.startPosition {
                    elementPositions[index] = elementPositions[index] + relativeLength
                }
                
                updateDocumentHeader()
                
                return
            }
            
            fatalError("Index out of range")
        }
    }
    
    /// Mutates the key-value pair like you would with a `Dictionary`'s `Index`
    public subscript(position: DocumentIndex) -> IndexIterationElement {
        get {
            var position = position.byteIndex
            
            guard let type = ElementType(rawValue: storage[position]) else {
                fatalError("Invalid type found in Document when searching the Document at the position \(position)")
            }
            
            position += 1
            var keyData = [UInt8]()
            
            while storage[position] != 0 {
                defer {
                    position += 1
                }
                
                keyData.append(storage[position])
            }
            
            // Skip beyond the null-terminator
            position += 1
            
            guard let key = String(bytesNoCopy: &keyData, length: keyData.count, encoding: String.Encoding.utf8, freeWhenDone: false) else {
                fatalError("Unable to construct the key bytes into a String")
            }
            
            guard let value = getValue(atDataPosition: position, withType: type) else {
                fatalError("Trying to access element in Document that does not exist")
            }
            
            return (key: key, value: value)
        }
        
        set {
            var position = position.byteIndex
            
            guard let type = ElementType(rawValue: storage[position]) else {
                fatalError("Invalid type found in Document when modifying the Document at the position \(position)")
            }
            
            let newBsonValue = newValue.value.makeBsonValue() 
            
            storage[position] = newBsonValue.typeIdentifier
            
            position += 1
            let stringPosition = position
            
            while storage[position] != 0 {
                position += 1
            }
            
            storage.removeSubrange(stringPosition..<position)
            
            storage.insert(contentsOf: [UInt8](newValue.key.utf8), at: stringPosition)
            position = stringPosition + newValue.key.characters.count + 1
            
            let length = getLengthOfElement(withDataPosition: position, type: type)
            
            storage.removeSubrange(position..<position+length)
            storage.insert(contentsOf: newBsonValue.bytes, at: position)
            
            updateDocumentHeader()
        }
    }
}
