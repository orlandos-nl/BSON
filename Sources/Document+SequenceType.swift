//
//  Document+SequenceType.swift
//  BSON
//
//  Created by Robbert Brandsma on 03-02-16.
//  Copyright © 2016 Robbert Brandsma. All rights reserved.
//

import Foundation

extension Document : SequenceType {
    /// As required by and documented in `SequenceType`
    public var startIndex: Int {
        return elements.startIndex
    }

    /// As required by and documented in `SequenceType`
    public var endIndex: Int {
        return elements.endIndex
    }
    
    /// As required by and documented in `SequenceType`
    public func indexForKey(key: String) -> Int? {
        return elements.indexOf({ $0.0 == key })
    }
    
    /// As required by and documented in `SequenceType`
    public subscript (key: String) -> BSONElement? {
        get {
            return elements.filter({ $0.0 == key }).first?.1
        }
        set {
            if let newValue = newValue {
                self.updateValue(newValue, forKey: key)
            }
        }
    }
    
    public subscript (key: Int) -> BSONElement? {
        get {
            return elements[key].1
        }
        set {
            guard let newValue = newValue else {
                let shouldKeepArray = self.validatesAsArray()
                
                elements.removeAtIndex(key)
                
                if shouldKeepArray {
                    self.enforceArray()
                }
                
                return
            }
            
            elements[key] = ("\(key)", newValue)
        }
    }
    
    /// As required by and documented in `SequenceType`
    public mutating func updateValue(value: BSONElement, forKey key: String) -> BSONElement? {
        guard let indexKey = self.indexForKey(key) else {
            elements.append((key, value))
            return nil
        }
        
        let oldElement = elements[indexKey].1
        
        elements[indexKey] = (key, value)
        
        return oldElement
    }
    
    /// As required by and documented in `SequenceType`
    public mutating func removeAtIndex(index: Int) -> (String, BSONElement) {
        return elements.removeAtIndex(index)
    }
    
    /// As required by and documented in `SequenceType`
    public mutating func removeValueForKey(key: String) -> BSONElement? {
        guard let index = self.indexForKey(key) else {
            return nil
        }
        
        return elements.removeAtIndex(index).1
    }
    
    /// As required by and documented in `SequenceType`
    public mutating func removeAll(keepCapacity keepCapacity: Bool = false) {
        elements.removeAll()
    }
    
    /// As required by and documented in `SequenceType`
    public var count: Int {
        return elements.count
    }
    
    /// As required by and documented in `SequenceType`
    public func generate() -> AnyGenerator<(String, BSONElement)> {
        var i = -1
        
        return AnyGenerator {
            i += 1
            
            return i < self.elements.count ? self.elements[i] : nil
        }
    }
    
    /// As required by and documented in `SequenceType`
    public var isEmpty: Bool {
        return elements.isEmpty
    }
}