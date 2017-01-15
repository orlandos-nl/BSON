//
//  Document+Subscripts.swift
//  BSON
//
//  Created by Robbert Brandsma on 17-08-16.
//
//

import Foundation

public enum SubscriptExpression {
    case string(String)
    case staticString(StaticString)
    case integer(Int)
}

public protocol SubscriptExpressionType {
    var subscriptExpression: SubscriptExpression { get }
}

extension String : SubscriptExpressionType {
    public var subscriptExpression: SubscriptExpression {
        return .string(self)
    }
}

extension StaticString : SubscriptExpressionType {
    public var subscriptExpression: SubscriptExpression {
        return .staticString(self)
    }
}

extension Int : SubscriptExpressionType {
    public var subscriptExpression: SubscriptExpression {
        return .integer(self)
    }
}

extension Document {
    public subscript(dotNotated key: String) -> ValueConvertible? {
        get {
            return self[raw: key.components(separatedBy: ".")]
        }
        set {
            self[raw: key.components(separatedBy: ".")] = newValue
        }
    }
    
    public subscript(raw parts: SubscriptExpressionType...) -> ValueConvertible? {
        get {
            return self[raw: parts]
        }
        set {
            self[raw: parts] = newValue
        }
    }
    
    /// Mutates the key-value pair like you would with a `Dictionary`
    public subscript(raw parts: [SubscriptExpressionType]) -> ValueConvertible? {
        get {
            if parts.count == 1 {
                switch parts[0].subscriptExpression {
                case .staticString(let part):
                    var data = [UInt8](repeating: 0, count: part.utf8CodeUnitCount)
                    memcpy(&data, part.utf8Start, data.count)
                    
                    guard let meta = getMeta(forKeyBytes: data) else {
                        return nil
                    }
                    
                    return getValue(atDataPosition: meta.dataPosition, withType: meta.type)
                case .string(let part):
                    guard let meta = getMeta(forKeyBytes: [UInt8](part.utf8)) else {
                        return nil
                    }
                    
                    return getValue(atDataPosition: meta.dataPosition, withType: meta.type)
                case .integer(let position):
                    guard elementPositions.count > position else {
                        fatalError("Index \(position) out of range")
                    }
                    
                    let elementPosition = elementPositions[position]
                    
                    guard let currentKey = getMeta(atPosition: elementPosition) else {
                        fatalError("Index \(position) out of range")
                    }
                    
                    return getValue(atDataPosition: currentKey.dataPosition, withType: currentKey.type)
                }
            } else if parts.count >= 2 {
                var parts = parts
                let firstPart = parts.removeFirst()
                
                return parts.count == 0 ? self[raw: firstPart] : self[raw: firstPart]?.documentValue?[raw: parts]
            } else {
                return nil
            }
        }
        
        set {
            if parts.count == 1 {
                switch parts[0].subscriptExpression {
                case .staticString(let part):
                    var data = [UInt8](repeating: 0, count: part.utf8CodeUnitCount)
                    memcpy(&data, part.utf8Start, data.count)
                    
                    let newValue = newValue?.makeBSONPrimitive()
                    
                    if let meta = getMeta(forKeyBytes: [UInt8](data)) {
                        let len = getLengthOfElement(withDataPosition: meta.dataPosition, type: meta.type)
                        let dataEndPosition = meta.dataPosition+len
                        
                        storage.removeSubrange(meta.dataPosition..<dataEndPosition)
                        
                        let oldLength = dataEndPosition - meta.dataPosition
                        let relativeLength: Int
                        
                        if let newValue = newValue {
                            let newBinary = newValue.makeBSONBinary()
                            storage.insert(contentsOf: newBinary, at: meta.dataPosition)
                            storage[meta.elementTypePosition] = newValue.typeIdentifier
                            relativeLength = newBinary.count - oldLength
                        } else {
                            relativeLength = -oldLength
                        }
                        
                        for (index, element) in elementPositions.enumerated() where element > meta.dataPosition {
                            elementPositions[index] = elementPositions[index] + relativeLength
                        }
                        
                        updateDocumentHeader()
                        
                        return
                    } else if let newValue = newValue {
                        self.append(newValue, forKey: data)
                    }
                case .string(let part):
                    let newValue = newValue?.makeBSONPrimitive()
                    
                    if let meta = getMeta(forKeyBytes: [UInt8](part.utf8)) {
                        let len = getLengthOfElement(withDataPosition: meta.dataPosition, type: meta.type)
                        let dataEndPosition = meta.dataPosition+len
                        
                        storage.removeSubrange(meta.dataPosition..<dataEndPosition)
                        
                        let oldLength = dataEndPosition - meta.dataPosition
                        let relativeLength: Int
                        
                        if let newValue = newValue {
                            let newBinary = newValue.makeBSONBinary()
                            storage.insert(contentsOf: newBinary, at: meta.dataPosition)
                            storage[meta.elementTypePosition] = newValue.typeIdentifier
                            relativeLength = newBinary.count - oldLength
                        } else {
                            relativeLength = -oldLength
                        }
                        
                        for (index, element) in elementPositions.enumerated() where element > meta.dataPosition {
                            elementPositions[index] = elementPositions[index] + relativeLength
                        }
                        
                        updateDocumentHeader()
                        
                        return
                    } else if let newValue = newValue {
                        self.append(newValue, forKey: part)
                    }
                case .integer(let position):
                    let newValue = newValue?.makeBSONPrimitive()
                    
                    guard let currentKey = getMeta(atPosition: elementPositions[position]) else {
                        fatalError("Index out of range")
                    }
                    
                    let len = getLengthOfElement(withDataPosition: currentKey.dataPosition, type: currentKey.type)
                    let dataEndPosition = currentKey.dataPosition+len
                    
                    storage.removeSubrange(currentKey.dataPosition..<dataEndPosition)
                    
                    let oldLength = dataEndPosition - currentKey.dataPosition
                    let relativeLength: Int
                    
                    if let newValue = newValue {
                        let newBinary = newValue.makeBSONBinary()
                        storage.insert(contentsOf: newBinary, at: currentKey.dataPosition)
                        storage[currentKey.startPosition] = newValue.typeIdentifier
                        relativeLength = newBinary.count - oldLength
                    } else {
                        relativeLength = -oldLength
                    }
                    
                    for (index, element) in elementPositions.enumerated() where element > currentKey.startPosition {
                        elementPositions[index] = elementPositions[index] + relativeLength
                    }
                    
                    updateDocumentHeader()
                }
            } else if parts.count >= 2 {
                var parts = parts
                let firstPart = parts.removeFirst()
                
                var doc = self[firstPart] as Document? ?? [:]
                doc[raw: parts] = newValue
                
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
            
            let newBsonValue = newValue.value.makeBSONPrimitive()
            
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
            storage.insert(contentsOf: newBsonValue.makeBSONBinary(), at: position)
            
            updateDocumentHeader()
        }
    }
}
