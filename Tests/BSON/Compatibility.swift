//
//  Compatibility.swift
//  BSON
//
//  Created by Robbert Brandsma on 17-05-16.
//
//

import XCTest

#if !swift(>=3.0)

    extension XCTestCase {
        func measure(block: () -> Void) {
            self.measureBlock(block)
        }
    }
    
    extension Array {
        func index(`where` predicate: (Element) throws -> Bool) rethrows -> Int? {
            return try self.indexOf(predicate)
        }
        
        mutating func remove(at index: Int) -> Element {
            return self.removeAtIndex(index)
        }
        
        init(repeating repeatedValue: Element, count: Int) {
            self.init(count: count, repeatedValue: repeatedValue)
        }
        
        mutating func append<C: CollectionType where C.Generator.Element == Element>(contentsOf newElements: C) {
            self.appendContentsOf(newElements)
        }
        
        mutating func insert(contentsOf collection: [Generator.Element], at position: Index) {
            self.insertContentsOf(collection, at: position)
        }
        
        mutating func replaceSubrange(range: Range<Index>, with collection: [Generator.Element]) {
            self.replaceRange(range, with: collection)
        }
        
        mutating func removeSubrange(range: Range<Index>) {
            self.removeRange(range)
        }
    }
    
    extension SequenceType {
        public func enumerated() -> EnumerateSequence<Self> {
            return enumerate()
        }
    }
    
#endif