//
//  Document+SequenceType.swift
//  BSON
//
//  Created by Robbert Brandsma on 03-02-16.
//  Copyright © 2016 Robbert Brandsma. All rights reserved.
//

import Foundation

extension Document : Sequence {
    /// As required by and documented in `SequenceType`
    public var startIndex: Int {
        return elements.startIndex
    }

    /// As required by and documented in `SequenceType`
    public var endIndex: Int {
        return elements.endIndex
    }
    
    /// As required by and documented in `SequenceType`
    public func index(forKey key: String) -> Int? {
        return elements.index(where:)(where: { $0.0 == key })
    }
    
    /// Supports dot syntax for subdocument access
    public subscript (key: String) -> Value {
        get {
            // first, try the literal value
            if let maybeValue = elements.filter({ $0.0 == key }).first?.1 {
                return maybeValue
            }
            
            let components = key.components(separatedBy: ".")

            var rest = components
            rest.removeFirst()
            var subKey = rest.joined(separator: ".")
            
            if let firstComponent = components.first, let value = elements.filter({ $0.0 == firstComponent }).first?.1, let document = value.documentValue where subKey.characters.count > 0 {
                // there is a document here!
                return document[subKey]
            }
            
            return .nothing
        }
        set {
            if case .nothing = newValue {
                self.removeValue(forKey: key)
            } else {
                self.updateValue(newValue, forKey: key)
            }
        }
    }
    
    public subscript (key: Int) -> Value {
        get {
            return elements[key].1
        }
        set {
            if case .nothing = newValue {
                let shouldKeepArray = self.validatesAsArray()
                
                elements.remove(at: key)
                
                if shouldKeepArray {
                    self.enforceArray()
                }
                
                return
            }
            
            elements[key] = ("\(key)", newValue)
        }
    }
    
    /// As required by and documented in `SequenceType`
    public mutating func updateValue(_ value: Value, forKey key: String) -> Value? {
        guard let indexKey = self.index(forKey: key) else {
            elements.append((key, value))
            return nil
        }
        
        let oldElement = elements[indexKey].1
        
        elements[indexKey] = (key, value)
        
        return oldElement
    }
    
    /// As required by and documented in `SequenceType`
    public mutating func remove(at index: Int) -> (String, Value) {
        return elements.remove(at: index)
    }
    
    /// As required by and documented in `SequenceType`
    public mutating func removeValue(forKey key: String) -> Value? {
        guard let index = self.index(forKey: key) else {
            return nil
        }
        
        return elements.remove(at: index).1
    }
    
    /// As required by and documented in `SequenceType`
    public mutating func removeAll(keepingCapacity: Bool = false) {
        elements.removeAll()
    }
    
    /// As required by and documented in `SequenceType`
    public var count: Int {
        return elements.count
    }
    
    /// As required by and documented in `SequenceType`
    #if !swift(>=3.0)
    public func generate() -> AnyGenerator<(String, Value)> {
        var i = -1
        
        return AnyGenerator {
            i += 1
            
            return i < self.elements.count ? self.elements[i] : nil
        }
    }
    #else
    public func makeIterator() -> AnyIterator<(String, Value)> {
        var i = -1
        
        return AnyIterator {
            i += 1
            
            return i < self.elements.count ? self.elements[i] : nil
        }
    }
    #endif
    
    /// As required by and documented in `SequenceType`
    public var isEmpty: Bool {
        return elements.isEmpty
    }
}