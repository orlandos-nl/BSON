//
//  Document+Operators.swift
//  BSON
//
//  Created by Robbert Brandsma on 17-08-16.
//
//

import Foundation

extension Document : Equatable {
    public static func ==(lhs: Document, rhs: Document) -> Bool {
        return lhs === rhs // for now
        // TODO: Implement proper comparison here.
    }
    
    /// Returns true if `lhs` and `rhs` store the same serialized data.
    /// Implies that `lhs` == `rhs`.
    public static func ===(lhs: Document, rhs: Document) -> Bool {
        return lhs.storage == rhs.storage
    }
}

extension Document {
    public static func +(lhs: Document, rhs: Document) -> Document {
        var new = lhs
        new += rhs
        return new
    }
    
    public static func +=(lhs: inout Document, rhs: Document) {
        let rhsIsSmaller = lhs.count > rhs.count
        let smallest = rhsIsSmaller ? rhs : lhs
        let other = rhsIsSmaller ? lhs : rhs
        
        let otherKeys = other.keys
        for key in smallest.keys {
            if otherKeys.contains(key) {
                lhs.removeValue(forKey: key)
            }
        }
        
        lhs.storage.removeLast()
        
        let appendData = rhs.storage[4..<rhs.storage.endIndex]
        lhs.storage.append(contentsOf: appendData)
        
        lhs.updateDocumentHeader()
        lhs.elementPositions = lhs.buildElementPositionsCache()
    }
}
