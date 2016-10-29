//
//  Document+Operators.swift
//  BSON
//
//  Created by Robbert Brandsma on 17-08-16.
//
//

import Foundation

extension _Document : Equatable {
    /// Compares two Documents to be equal to each other
    ///
    /// TODO: Implement fast comparison here
    static func ==(lhs: _Document, rhs: _Document) -> Bool {
        guard lhs.count == rhs.count else {
            return false
        }
        
        for (key, value) in lhs {
            guard rhs[key] == value else {
                return false
            }
        }
        
        return lhs.isArray == rhs.isArray
    }
    
    /// Returns true if `lhs` and `rhs` store the same serialized data.
    /// Implies that `lhs` == `rhs`.
    public static func ===(lhs: _Document, rhs: _Document) -> Bool {
        return lhs.storage == rhs.storage
    }
}

extension _Document {
    /// Appends `rhs` to `lhs` overwriting the keys from `lhs` when necessary
    ///
    /// - returns: The modified `lhs`
    public static func +(lhs: _Document, rhs: _Document) -> _Document {
        var new = lhs
        new += rhs
        return new
    }
    
    /// Appends `rhs` to `lhs` overwriting the keys from `lhs` when necessary
    public static func +=(lhs: inout _Document, rhs: _Document) {
        let rhsIsSmaller = lhs.count > rhs.count
        let smallest = rhsIsSmaller ? rhs : lhs
        let other = rhsIsSmaller ? lhs : rhs
        
        let otherKeys = other.keys
        for key in smallest.keys {
            if otherKeys.contains(key) {
                lhs.removeValue(forKey: key)
            }
        }
        
        let appendData = rhs.storage[4..<rhs.storage.endIndex]
        lhs.storage.append(contentsOf: appendData)
        
        lhs.updateDocumentHeader()
        lhs.elementPositions = lhs.buildElementPositionsCache()
    }
}
