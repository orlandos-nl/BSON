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
    
    func makeIndexKey(from keyParts: [SubscriptExpressionType]) -> IndexKey {
        var parts = [KittenBytes]()
        
        indexKeyBuilder: for part in keyParts {
            switch part.subscriptExpression {
            case .kittenBytes(let bytes):
                parts.append(bytes)
            case .integer(let pos):
                guard pos > -1 else {
                    parts.append(KittenBytes(Bytes(pos.description.utf8)))
                    continue indexKeyBuilder
                }
                
                var i = 0
                var pointer: Int
                
                if parts.count == 0 {
                    pointer = 4
                } else {
                    guard let meta = getMeta(for: IndexKey(parts)) else {
                        parts.append(KittenBytes(Bytes(pos.description.utf8)))
                        continue indexKeyBuilder
                    }
                    
                    pointer = meta.dataPosition &+ 4
                }
                
                keySkipper: while i < pos {
                    defer { i = i &+ 1 }
                    
                    for i in pointer..<storage.count {
                        guard self.storage[i] != 0 else {
                            guard let type = ElementType(rawValue: self.storage[pointer]) else {
                                parts.append(KittenBytes(Bytes(pos.description.utf8)))
                                continue indexKeyBuilder
                            }
                            
                            pointer = i &+ 1 &+ getLengthOfElement(withDataPosition: i &+ 1, type: type)
                            
                            continue keySkipper
                        }
                    }
                }
                
                var key = Bytes()
                
                pointer = pointer &+ 1
                
                guard pointer < storage.count else {
                    parts.append(KittenBytes(key))
                    
                    continue indexKeyBuilder
                }
                
                for i in pointer..<storage.count {
                    guard self.storage[i] != 0 else {
                        parts.append(KittenBytes(key))
                        
                        continue indexKeyBuilder
                    }
                    
                    key.append(storage[i])
                }
            }
        }
        
        return IndexKey(parts)
    }
    
    /// Mutates the key-value pair like you would with a `Dictionary`
    public subscript(parts: [SubscriptExpressionType]) -> Primitive? {
        get {
            let key = makeIndexKey(from: parts)
            
            if let position = searchTree.storage[key] {
                guard let currentKey = getMeta(atPosition: position) else {
                    return nil
                }
                
                return getValue(atDataPosition: currentKey.dataPosition, withType: currentKey.type)
            } else if let metadata = index(recursive: nil, lookingFor: key) {
                return getValue(atDataPosition: metadata.dataPosition, withType: metadata.type)
            }
            
            return nil
        }
        
        set {
            let key = makeIndexKey(from: parts)
            
            guard let meta = getMeta(for: key) else {
                if let newValue = newValue {
                    self.update(value: newValue, for: key)
                }
                
                return
            }
            
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
                
                for (key, startPosition) in searchTree.storage where startPosition > meta.elementTypePosition {
                    searchTree.storage[key] = startPosition + relativeLength
                }
            } else if let lastKey = key.keys.last {
                storage.removeSubrange(meta.elementTypePosition..<(meta.elementTypePosition + lastKey.bytes.count + 2 + len))
                // key + null terminator + type
                relativeLength = -((lastKey.bytes.count + 2) + len)
                
                searchTree.storage[key] = nil
                
                for (key, startPosition) in searchTree.storage where startPosition > meta.elementTypePosition {
                    self.searchTree.storage[key] = startPosition + relativeLength
                }
            } else {
                return
            }
            
            for i in 1 ..< parts.count {
                updateDocumentHeader(for: IndexKey(Array(parts[0..<i])), relativeLength: relativeLength)
            }
            
            updateDocumentHeader()
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
