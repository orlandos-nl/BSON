//
//  Document+Subscripts.swift
//  BSON
//
//  Created by Robbert Brandsma on 17-08-16.
//
//

import Foundation

public enum SubscriptExpression {
    case key(String)
    case integer(Int)
}

public protocol SubscriptExpressionType {
    var subscriptExpression: SubscriptExpression { get }
}

extension String : SubscriptExpressionType {
    public var subscriptExpression: SubscriptExpression {
        return .key(self)
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
    
    func makeIndexKey(from keyParts: [SubscriptExpressionType]) -> [IndexKey] {
        var parts = [IndexKey]()
        
        indexKeyBuilder: for part in keyParts {
            switch part.subscriptExpression {
            case .key(let key):
                parts.append(IndexKey(KittenBytes([UInt8](key.utf8))))
            case .integer(let pos):
                guard pos > -1 else {
                    parts.append(IndexKey(KittenBytes(Bytes(pos.description.utf8))))
                    continue indexKeyBuilder
                }
                
                var i = 0
                var pointer: Int
                
                if parts.count == 0 {
                    pointer = 0
                } else {
                    // TODO: Leave this in?
                    guard let meta = getMeta(for: parts) else {
                        parts.append(IndexKey(KittenBytes(Bytes(pos.description.utf8))))
                        continue indexKeyBuilder
                    }
                    
                    pointer = meta.dataPosition &+ 4
                }
                
                keySkipper: while i < pos {
                    defer { i = i &+ 1 }
                    
                    for i in pointer..<storage.count {
                        guard self.storage[i] != 0 else {
                            guard let type = ElementType(rawValue: self.storage[pointer]) else {
                                parts.append(IndexKey(KittenBytes(Bytes(pos.description.utf8))))
                                continue indexKeyBuilder
                            }
                            
                            let len = getLengthOfElement(withDataPosition: i &+ 1, type: type)
                            
                            guard len >= 0 else {
                                return []
                            }
                            
                            pointer = i &+ 1 &+ len
                            
                            continue keySkipper
                        }
                    }
                }
                
                var key = Bytes()
                
                pointer = pointer &+ 1
                
                guard pointer < storage.count else {
                    parts.append(IndexKey(KittenBytes(key)))
                    
                    continue indexKeyBuilder
                }
                
                for i in pointer..<storage.count {
                    guard self.storage[i] != 0 else {
                        parts.append(IndexKey(KittenBytes(key)))
                        
                        continue indexKeyBuilder
                    }
                    
                    key.append(storage[i])
                }
            }
        }
        
        return parts
    }
    
    /// Mutates the key-value pair like you would with a `Dictionary`
    internal subscript(parts: [KittenBytes]) -> Primitive? {
        get {
            let key = parts.map(IndexKey.init)
            
            if let position = searchTree[position: key] {
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
            let key = parts.map(IndexKey.init)
            
            guard let newValue = newValue else {
                unset(key)
                return
            }
            
            self.set(value: newValue, for: key)
        }
    }
    
    /// Mutates the key-value pair like you would with a `Dictionary`
    public subscript(parts: [SubscriptExpressionType]) -> Primitive? {
        get {
            let key = makeIndexKey(from: parts)
            
            if let position = searchTree[position: key] {
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
            
            guard let newValue = newValue else {
                unset(key)
                return
            }
            
            self.set(value: newValue, for: key)
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
            
            guard let key = String(bytes: keyData, encoding: .utf8) else {
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
            
            guard length >= 0 else {
                return
            }
            
            storage.removeSubrange(position..<position+length)
            storage.insert(contentsOf: newBsonValue.makeBinary(), at: position)
        }
    }
}
