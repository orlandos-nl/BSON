//
//  Document+Flattening.swift
//  BSON
//
//  Created by Robbert Brandsma on 17-08-16.
//
//

import Foundation

extension Document {
    /// Flattens the document, removing any subdocuments and adding their key-value pairs as individual key-value pairs on the parent document.
    ///
    /// Consider having a document like this:
    ///
    ///     [
    ///         "foo": "bar",
    ///         "details": [
    ///             "cow": "henk",
    ///             "chicken": "fred"
    ///         ]
    ///     ]
    ///
    /// After calling `flatten()`, it will be:
    ///
    ///     [
    ///         "foo": "bar",
    ///         "details.cow": "henk",
    ///         "details.chicken": "fred"
    ///     ]
    ///
    public mutating func flatten(skippingArrays skipArrays: Bool = false) {
        enum FlattenError : Error {
            case invalidDocument
        }
        
        /// Flattens the document at the given position. Returns the (new) position past the document.
        func flatten(start: Int, keyPrefixBytes: ArraySlice<Byte>, isRootDocument: Bool) throws -> Int {
            var index = start
            
            // We're now at the start of this document, where the 4-byte length resides. We'll delete that.
            if !isRootDocument {
                storage.removeSubrange(index..<index+4)
            } else {
                // or, in the case of the root document, move past it...
                index += 4
            }
            
            // Loop over all the elements of this document:
            while index < storage.count && storage[index] != 0 {
                if !isRootDocument {
                    // Prefix the key, and a full stop (.)
                    storage.insert(0x2e, at: index+1)
                    storage.insert(contentsOf: keyPrefixBytes, at: index+1)
                }
                
                guard let (dataPosition, type, startPosition) = getMeta(atPosition: index) else {
                    throw FlattenError.invalidDocument
                }
                
                // If the element is not a document (or array, which is a document), move past it.
                guard (type == .arrayDocument && !skipArrays) || type == .document else {
                    index = dataPosition + getLengthOfElement(withDataPosition: dataPosition, type: type)
                    continue
                }
                
                // The element is an array or document, so we should flatten that, too
                
                // The new key prefix bytes start at the key of the current element (the parent document) and end
                let subKeyPrefixBytes = storage[startPosition+1...dataPosition-2]
                index = try flatten(start: dataPosition, keyPrefixBytes: subKeyPrefixBytes, isRootDocument: false)
                
                // Finally, remove the BSON key and type of the parent document
                let range = startPosition..<dataPosition
                storage.removeSubrange(range)
                index = index - range.count
            }
            
            // Remove the document null terminator:
            if !isRootDocument {
                storage.remove(at: index)
            }
            
            return index
        }
        
        let _ = try? flatten(start: 0, keyPrefixBytes: ArraySlice<Byte>(), isRootDocument: true)
        
        // After flattening, we should recalculate the index and document header:
        self.searchTree = self.buildElementPositionsCache()
        self.updateDocumentHeader()
    }
    
    /// Returns the document, removing any subdocuments and adding their key-value pairs as individual key-value pairs on the parent document.
    ///
    /// Consider having a document like this:
    ///
    ///     [
    ///         "foo": "bar",
    ///         "details": [
    ///             "cow": "henk",
    ///             "chicken": "fred"
    ///         ]
    ///     ]
    ///
    /// Calling `flattened()` will return:
    ///
    ///     [
    ///         "foo": "bar",
    ///         "details.cow": "henk",
    ///         "details.chicken": "fred"
    ///     ]
    ///
    public func flattened() -> Document {
        var doc = self
        doc.flatten()
        return doc
    }
}
