//
//  Document+Subscripts.swift
//  BSON
//
//  Created by Robbert Brandsma on 17-08-16.
//
//

import Foundation
import KittenCore

public enum SubscriptExpression {
    case kittenBytes(KittenBytes)
    case integer(Int)
}

public protocol SubscriptExpressionType {
    var subscriptExpression: SubscriptExpression { get }
}

extension String : SubscriptExpressionType {
    public var subscriptExpression: SubscriptExpression {
        return .kittenBytes(self.kittenBytes)
    }
}

extension StaticString : SubscriptExpressionType {
    public var subscriptExpression: SubscriptExpression {
        return .kittenBytes(self.kittenBytes)
    }
}

extension KittenBytes : SubscriptExpressionType {
    public var subscriptExpression: SubscriptExpression {
        return .kittenBytes(self)
    }
}

extension Int : SubscriptExpressionType {
    public var subscriptExpression: SubscriptExpression {
        return .integer(self)
    }
}

extension Document {
    public subscript(dotNotated key: String) -> Primitive? {
        get {
            return self[key.components(separatedBy: ".")]
        }
        set {
            self[key.components(separatedBy: ".")] = newValue
        }
    }
    
    public subscript(parts: SubscriptExpressionType...) -> Primitive? {
        get {
            return self[parts]
        }
        set {
            self[parts] = newValue
        }
    }
    
    /// Mutates the key-value pair like you would with a `Dictionary`
    public subscript(parts: [SubscriptExpressionType]) -> Primitive? {
        get {
            if parts.count == 1 {
                switch parts[0].subscriptExpression {
                case .kittenBytes(let part):
                    guard let meta = getMeta(forKeyBytes: part.bytes) else {
                        return nil
                    }
                    
                    return getValue(atDataPosition: meta.dataPosition, withType: meta.type)
                case .integer(let position):
                    guard searchTree.count > position else {
                        return nil
                    }
                    
                    let elementPosition = sortedTree()[position].1
                    
                    guard let currentKey = getMeta(atPosition: elementPosition) else {
                        return nil
                    }
                    
                    return getValue(atDataPosition: currentKey.dataPosition, withType: currentKey.type)
                }
            } else if parts.count >= 2 {
                var parts = parts
                let firstPart = parts.removeFirst()
                
                return parts.count == 0 ? self[firstPart] : (self[firstPart] as? Document)?[parts]
            } else {
                return nil
            }
        }
        
        set {
            if parts.count == 1 {
                switch parts[0].subscriptExpression {
                case .kittenBytes(let part):
                    if let meta = getMeta(forKeyBytes: part.bytes) {
                        let len = getLengthOfElement(withDataPosition: meta.dataPosition, type: meta.type)
                        let dataEndPosition = meta.dataPosition+len
                        
                        let relativeLength: Int
                        
                        if let newValue = newValue {
                            storage.removeSubrange(meta.dataPosition..<dataEndPosition)
                            let oldLength = dataEndPosition - meta.dataPosition
                            let newBinary = newValue.makeBinary()
                            storage.insert(contentsOf: newBinary, at: meta.dataPosition)
                            storage[meta.elementTypePosition] = newValue.typeIdentifier
                            relativeLength = newBinary.count - oldLength
                            
                            for (key, startPosition) in searchTree where startPosition > meta.elementTypePosition {
                                searchTree[key] = startPosition + relativeLength
                            }
                        } else {
                            storage.removeSubrange(meta.elementTypePosition..<(meta.elementTypePosition + part.bytes.count + 2 + len))
                            // key + null terminator + type
                            relativeLength = -((part.bytes.count + 2) + len)
                            
                            searchTree[part] = nil
                            
                            for (key, startPosition) in searchTree where startPosition > meta.dataPosition + relativeLength {
                                searchTree[key] = startPosition + relativeLength
                            }
                        }
                        
                        updateDocumentHeader()
                        
                        return
                    } else if let newValue = newValue {
                        self.append(newValue, forKey: part.bytes)
                    }
                case .integer(let position):
                    let (key, elementPosition) = sortedTree()[position]
                    
                    guard let meta = getMeta(atPosition: elementPosition) else {
                        fatalError("Index out of range")
                    }
                    
                    let len = getLengthOfElement(withDataPosition: meta.dataPosition, type: meta.type)
                    let dataEndPosition = meta.dataPosition+len
                    
                    storage.removeSubrange(meta.dataPosition..<dataEndPosition)
                    
                    let relativeLength: Int
                    
                    if let newValue = newValue {
                        let newBinary = newValue.makeBinary()
                        storage.insert(contentsOf: newBinary, at: meta.dataPosition)
                        storage[meta.startPosition] = newValue.typeIdentifier
                        relativeLength = newBinary.count - len
                    } else {
                        storage.removeSubrange(meta.startPosition..<(meta.startPosition + key.bytes.count + 2 + len))
                        // key + null terminator + type
                        relativeLength = -((key.bytes.count + 2) + len)
                        
                        searchTree[key] = nil
                    }
                    
                    let affectedPosition = relativeLength >= 0 ? meta.dataPosition : meta.dataPosition + relativeLength
                    
                    for (key, startPosition) in searchTree where startPosition > affectedPosition {
                        searchTree[key] = startPosition + relativeLength
                    }
                    
                    updateDocumentHeader()
                }
            } else if parts.count >= 2 {
                var parts = parts
                let firstPart = parts.removeFirst()
                
                var doc = self[firstPart] as? Document ?? [:]
                doc[parts] = newValue
                
                self[firstPart] = doc
            }
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
            var keyData = Bytes()
            
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
            
            let newBsonValue = newValue.value
            
            storage[position] = newBsonValue.typeIdentifier
            
            position += 1
            let stringPosition = position
            
            while storage[position] != 0 {
                position += 1
            }
            
            storage.removeSubrange(stringPosition..<position)
            
            storage.insert(contentsOf: Bytes(newValue.key.utf8), at: stringPosition)
            position = stringPosition + newValue.key.characters.count + 1
            
            let length = getLengthOfElement(withDataPosition: position, type: type)
            
            storage.removeSubrange(position..<position+length)
            storage.insert(contentsOf: newBsonValue.makeBinary(), at: position)
            
            updateDocumentHeader()
        }
    }
}
