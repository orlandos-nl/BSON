//
//  Compatibility.swift
//  BSON
//
//  Created by Robbert Brandsma on 17-05-16.
//
//

import Foundation

#if !swift(>=3.0)

    typealias ErrorProtocol = ErrorType
    typealias Sequence = SequenceType
    
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
    
    extension String {
        func components(separatedBy separator: String) -> [String] {
            return self.componentsSeparatedByString(separator)
        }
    }
    
    extension SequenceType {
        func makeIterator() -> Generator {
            return self.generate()
        }
    }
    
    extension SequenceType where Generator.Element == String {
        func joined(separator separator: String) -> String {
            return self.joinWithSeparator(separator)
        }
    }
    
    extension NSData {
        @objc(kaas:koekjes:salade:) func write(toFile path: String, options writeOptionsMask: NSDataWritingOptions = []) throws {
            try self.writeToFile(path, options: writeOptionsMask)
        }
    }
    
    extension UnsafePointer {
        typealias Pointee = Memory
        var pointee: Pointee {
            return self.memory
        }
    }
    
    extension CollectionType where Generator.Element : Equatable {
        func index(of element: Self.Generator.Element) -> Self.Index? {
            return self.indexOf(element)
        }
        
        func split(separator separator: Self.Generator.Element, maxSplits: Int = Int.max, omittingEmptySubsequences: Bool = true) -> [Self.SubSequence] {
            return self.split(separator, maxSplit: maxSplits, allowEmptySlices: !omittingEmptySubsequences)
        }
    }
    
    extension NSDate {
        @objc(kaas:) func isEqual(to otherDate: NSDate) -> Bool {
            return self.isEqualToDate(otherDate)
        }
    }

#endif