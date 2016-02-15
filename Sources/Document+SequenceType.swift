//
//  Document+SequenceType.swift
//  BSON
//
//  Created by Robbert Brandsma on 03-02-16.
//  Copyright © 2016 Robbert Brandsma. All rights reserved.
//

import Foundation

extension Document : SequenceType {
    public typealias Key = String
    public typealias FooValue = BSONElementConvertible
    public typealias Index = DictionaryIndex<Key, FooValue>
    
    /// As required by and documented in `SequenceType`
    public var startIndex: DictionaryIndex<Key, FooValue> {
        return elements.startIndex
    }

    /// As required by and documented in `SequenceType`
    public var endIndex: DictionaryIndex<Key, FooValue> {
        return elements.endIndex
    }
    
    /// As required by and documented in `SequenceType`
    public func indexForKey(key: Key) -> DictionaryIndex<Key, FooValue>? {
        return elements.indexForKey(key)
    }
    
    /// As required by and documented in `SequenceType`
    public subscript (key: Key) -> FooValue? {
        get {
            return elements[key]
        }
        set {
            elements[key] = newValue
        }
    }
    
    /// document[4] is the same as document["4"]
    public subscript (key: Int) -> BSONElementConvertible? {
        return self["\(key)"]
    }
    
    /// As required by and documented in `SequenceType`
    public subscript (position: DictionaryIndex<Key, FooValue>) -> (Key, FooValue) {
        return elements[position]
    }
    
    /// As required by and documented in `SequenceType`
    public mutating func updateValue(value: FooValue, forKey key: Key) -> FooValue? {
        return elements.updateValue(value, forKey: key)
    }
    
    /// As required by and documented in `SequenceType`
    public mutating func removeAtIndex(index: DictionaryIndex<Key, FooValue>) -> (Key, FooValue) {
        return elements.removeAtIndex(index)
    }
    
    /// As required by and documented in `SequenceType`
    public mutating func removeValueForKey(key: Key) -> FooValue? {
        return elements.removeValueForKey(key)
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
    public func generate() -> DictionaryGenerator<Key, FooValue> {
        return elements.generate()
    }
    
    /// As required by and documented in `SequenceType`
    public var keys: LazyMapCollection<[Key : FooValue], Key> {
        return elements.keys
    }
    
    /// As required by and documented in `SequenceType`
    public var values: LazyMapCollection<[Key : FooValue], FooValue> {
        return elements.values
    }
    
    /// As required by and documented in `SequenceType`
    public var isEmpty: Bool {
        return elements.isEmpty
    }
}