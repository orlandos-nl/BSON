//
//  Document+Validation.swift
//  BSON
//
//  Created by Robbert Brandsma on 17-08-16.
//
//

import Foundation

extension Document {
    /// Validates the current `Document` and checks for any and all errors
    ///
    /// - returns: The status of validation. `true` for valid and vice-versa
    public func validate() -> Bool {
        if invalid {
            return false
        }
        
        var position = 0
        
        while position < storage.count {
            // Get the element type
            guard let type = ElementType(rawValue: storage[position]) else {
                return false
            }
            
            // Position after the element type
            position += 1
            
            // Find the end of the key - if any
            while position < storage.count && storage[position] != 0 {
                position += 1
            }
            
            // Check that the String ends with a null-terminator
            guard position < storage.count, storage[position] == 0 else {
                return false
            }
            
            position += 1
            
            // get the length, safely
            let length: Int
            
            switch type {
            // Static:
            case .objectId:
                length = 12
            case .double, .int64, .utcDateTime, .timestamp:
                length = 8
            case .int32:
                length = 4
            case .boolean:
                length =  1
            case .nullValue, .minKey, .maxKey:
                length = 0
            // Calculated:
            case .regex: // defined as "cstring cstring"
                length = getLengthOfElement(withDataPosition: position, type: type)
                
                guard length >= 0 else {
                    return false
                }
            default:
                guard storage.count >= position + 4 + (type == .binary ? 1 : 0) else {
                    return false
                }
                
                length = getLengthOfElement(withDataPosition: position, type: type)
                
                guard length >= 0 else {
                    return false
                }
            }
            
            if type == .document || type == .arrayDocument {
                guard position + length - 1 < storage.count else {
                    return false
                }
                
                let doc = Document(data: Array(storage[position...position + length - 1]))
                guard doc.validate() else {
                    return false
                }
                
                // The BSON spec requires this, but MongoDB's unit tests specifically require ignoring this
//                if type == .arrayDocument && !doc.validatesAsArray() {
//                    return false
//                }
            }
            
            if type == .boolean {
                guard storage[position] == 0x00 || storage[position] == 0x01 else {
                    return false
                }
            }
            
            // Position after the value
            position += length
            
            if type == .string {
                guard length > 4, position - 1 < storage.count, storage[position - 1] == 0x00 else {
                    return false
                }
            }
            
            // Check if the length is correct
            guard storage.count >= position else {
                return false
            }
        }
        
        return position == storage.count
    }
}
