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
    
    // Remap everything to elements
    public var startIndex: DictionaryIndex<Key, FooValue> {
        return elements.startIndex
    }
    
    public var endIndex: DictionaryIndex<Key, FooValue> {
        return elements.endIndex
    }
    
    public func indexForKey(key: Key) -> DictionaryIndex<Key, FooValue>? {
        return elements.indexForKey(key)
    }
    
    public subscript (key: Key) -> FooValue? {
        return elements[key]
    }
    
    // Add extra subscript for Integers since a Document can also be a BSON Array
    public subscript (key: Int) -> BSONElementConvertible? {
        return self["\(key)"]
    }
    
    public subscript (position: DictionaryIndex<Key, FooValue>) -> (Key, FooValue) {
        return elements[position]
    }
    
    public mutating func updateValue(value: FooValue, forKey key: Key) -> FooValue? {
        return elements.updateValue(value, forKey: key)
    }
    
    // WORKS?
    public mutating func removeAtIndex(index: DictionaryIndex<Key, FooValue>) -> (Key, FooValue) {
        return elements.removeAtIndex(index)
    }
    
    public mutating func removeValueForKey(key: Key) -> FooValue? {
        return elements.removeValueForKey(key)
    }
    
    public mutating func removeAll(keepCapacity keepCapacity: Bool = false) {
        elements.removeAll()
    }
    
    public var count: Int {
        return elements.count
    }
    
    public func generate() -> DictionaryGenerator<Key, FooValue> {
        return elements.generate()
    }
    
    public var keys: LazyMapCollection<[Key : FooValue], Key> {
        return elements.keys
    }
    
    public var values: LazyMapCollection<[Key : FooValue], FooValue> {
        return elements.values
    }
    
    public var isEmpty: Bool {
        return elements.isEmpty
    }
}