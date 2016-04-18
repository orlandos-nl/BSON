//
//  Document.swift
//  BSON
//
//  Created by Robbert Brandsma on 23-01-16.
//  Copyright © 2016 Robbert Brandsma. All rights reserved.
//

import Foundation

/// The base type for all BSON data, defined in the spec as:
///
/// `document	::=	int32 e_list "\x00"`
///
/// A document is comparable with a Swift `Array`or `Dictionary`. It can thus be initialized
/// by using an array or dictionary literal:
///
/// ```
/// let d: Document = ["key": "value"]
/// let a: Document = ["value 1", "value 2"]
/// ```
///
/// In the BSON specification, the following is said about BSON arrays: 
///
/// Array - The document for an array is a normal BSON document with integer values for the keys, starting with 0 and continuing sequentially. For example, the array `['red', 'blue']` would be encoded as the document `{'0': 'red', '1': 'blue'}`. The keys must be in ascending numerical order.
/// 
/// Because this BSON library exports all documents alphabetically, every document only numerical subsequential keys starting at '0' will be treated as an array.
public struct Document {
    /// Element storage
    internal var elements = [(String, Value)]()
    
    /// Initialize a BSON document with the data from the given Foundation `NSData` object.
    /// 
    /// Will throw a `DeserializationError` when the document is invalid.
    public init(data: NSData) throws {
        var byteArray = [UInt8](repeating: 0, count: data.length)
        data.getBytes(&byteArray, length: byteArray.count)
        
        var 🖕 = 0
        
        try self.init(data: byteArray, consumedBytes: &🖕)
    }
    
    /// Initialize a BSON document with the given byte array.
    ///
    /// Will throw a `DeserializationError` when the document is invalid.
    public init(data: [UInt8]) throws {
        var 🖕 = 0
        try self.init(data: data, consumedBytes: &🖕)
    }
    
    /// Internal initializer used by all other initializers and for initializing embedded documents.
    internal init(data: [UInt8], consumedBytes: inout Int) throws {
        // A BSON document cannot be smaller than 5 bytes (which would be an empty document)
        guard data.count >= 5 else {
            throw DeserializationError.InvalidDocumentLength
        }
        
        // The first four bytes of a document represent the total size of the document
        let documentLength = Int(Int32(littleEndian: UnsafePointer<Int32>(data).pointee))
        guard data.count >= documentLength else {
            throw DeserializationError.InvalidDocumentLength
        }
        
        defer {
            consumedBytes = documentLength
        }
        
        // Parse! Loop over the element list.
        var position = 4
        while position < documentLength {
            // The first byte in an element is the element type
            let elementType = data[position]
            position += 1
            
            // Is this the end of the document?
            if elementType == 0x00 && position == documentLength {
                return
            }
            
            // Now that we have the type, parse the name
            guard let stringTerminatorIndex = data[position..<documentLength].index(of:)(of: 0) else {
                throw DeserializationError.ParseError
            }
            
            let keyData = Array(data[position...stringTerminatorIndex])
            let elementName = try String.instantiateFromCString(bsonData: keyData)
            
            position = stringTerminatorIndex + 1
            
            func remaining() -> Int {
                return data.count - position
            }
            
            let value: Value
            elementDeserialization: switch elementType {
            case 0x01: // double
                guard remaining() >= 8 else {
                    throw DeserializationError.InvalidElementSize
                }
                
                let double = UnsafePointer<Double>(Array(data[position..<position+8])).pointee
                value = .double(double)
                
                position += 8
            case 0x02: // string
                // Check for null-termination and at least 5 bytes (length spec + terminator)
                guard remaining() >= 5 else {
                    throw DeserializationError.InvalidElementSize
                }
                
                // Get the length
                let length = try Int32.instantiate(bsonData: Array(data[position...position+3]))
                
                // Check if the data is at least the right size
                guard data.count-position >= Int(length) + 4 else {
                    throw DeserializationError.ParseError
                }
                
                // Empty string
                if length == 1 {
                    position += 5
                    
                    value = .string("")
                    break elementDeserialization
                }
                
                guard length > 0 else {
                    throw DeserializationError.ParseError
                }
                
                var stringData = Array(data[position+4..<position+Int(length + 3)])
                
                guard let string = String(bytesNoCopy: &stringData, length: stringData.count, encoding: NSUTF8StringEncoding, freeWhenDone: false) else {
                    throw DeserializationError.ParseError
                }

                value = .string(string)
                position += Int(length) + 4
            case 0x03, 0x04: // document / array
                let length = Int(try Int32.instantiate(bsonData: Array(data[position..<position+4])))
                let subData = Array(data[position..<position+length])
                let document = try Document(data: subData)
                value = elementType == 0x03 ? .document(document) : .array(document)
                position += length
            case 0x05: // binary
                guard remaining() >= 5 else {
                    throw DeserializationError.InvalidElementSize
                }
                
                let length = try Int32.instantiate(bsonData: Array(data[position..<position+4]))
                let subType = data[position+4]
                
                guard remaining() >= Int(length) + 5 else {
                    throw DeserializationError.InvalidElementSize
                }
                
                let realData = length > 0 ? Array(data[position+5...position+Int(4+length)]) : []
                // length + subType + data
                position += 4 + 1 + Int(length)
                
                value = .binary(subtype: BinarySubtype(rawValue: subType), data: realData)
            case 0x07: // objectid
                guard remaining() >= 12 else {
                    throw DeserializationError.InvalidElementSize
                }
                
                value = .objectId(try ObjectId(bsonData: Array(data[position..<position+12])))
                position += 12
            case 0x08: // boolean
                guard remaining() >= 1 else {
                    throw DeserializationError.InvalidElementSize
                }
                
                position += 1
                value = data[position] == 0x00 ? .boolean(false) : .boolean(true)
            case 0x09: // utc datetime
                let interval = try Int64.instantiate(bsonData: Array(data[position..<position+8]))
                let date = NSDate(timeIntervalSince1970: Double(interval) / 1000) // BSON time is in ms
                
                value = .dateTime(date)
                position += 8
            case 0x0A: // null
                value = .null
            case 0x0B: // regular expression
                let k = data.split(separator: 0, maxSplits: 2, omittingEmptySubsequences: false)
                guard k.count >= 2 else {
                    throw DeserializationError.InvalidElementSize
                }
                
                let patternData = Array(k[0])
                let pattern = try String.instantiateFromCString(bsonData: patternData + [0x00])
                
                let optionsData = Array(k[1])
                let options = try String.instantiateFromCString(bsonData: optionsData + [0x00])
                
                // +1 for the null which is removed by the split
                position += patternData.count+1 + optionsData.count+1
                
                value = .regularExpression(pattern: pattern, options: options)
            case 0x0D: // javascript code
                var codeSize = 0
                let code = try String.instantiate(bsonData: Array(data[position..<data.endIndex]), consumedBytes: &codeSize)
                position += codeSize
                value = .javascriptCode(code)
            case 0x0F:
                // min length is 14 bytes: 4 for the int32, 5 for the string and 5 for the document
                guard remaining() >= 14 else {
                    throw DeserializationError.InvalidElementSize
                }
                
                // why did they include this? it's not needed. whatever. we'll validate it.
                let totalLength = Int(try Int32.instantiate(bsonData: Array(data[position..<position+4])))
                guard remaining() >= totalLength else {
                    throw DeserializationError.InvalidElementSize
                }
                
                let stringDataAndMore = Array(data[position+4..<position+totalLength])
                var trueCodeSize = 0
                let code = try String.instantiate(bsonData: stringDataAndMore, consumedBytes: &trueCodeSize)
                
                // - 4 (length) - 5 (document)
                guard stringDataAndMore.count - 4 - 5 >= trueCodeSize else {
                    throw DeserializationError.InvalidElementSize
                }
                
                let scopeDataAndMaybeMore = Array(stringDataAndMore[trueCodeSize..<stringDataAndMore.endIndex])
                var trueScopeSize = 0
                let scope = try Document(data: scopeDataAndMaybeMore, consumedBytes: &trueScopeSize)
                
                // Validation, yay!
                guard totalLength == 4 + trueCodeSize + trueScopeSize else {
                    throw DeserializationError.InvalidElementSize
                }
                
                position += 4 + trueCodeSize + trueScopeSize
                
                value = .javascriptCodeWithScope(code: code, scope: scope)
            case 0x10: // int32
                value = .int32(try Int32.instantiate(bsonData: Array(data[position..<position+4])))
                position += 4
            case 0x11, 0x12: // timestamp, int64
                let integer = try Int64.instantiate(bsonData: Array(data[position..<position+8]))
                value = elementType == 0x11 ? .timestamp(integer) : .int64(integer)
                position += 8
            case 0xFF: // MinKey
                value = .minKey
            case 0x7F: // MaxKey
                value = .maxKey
            default:
                throw DeserializationError.UnknownElementType
            }
            
            elements.append((elementName, value))
        }
    }
}

extension Document {
    /// Instantiates zero or more `Document`s from the given data. This data is formatted like this:
    /// `let data = document1.bsonData + document2.bsonData`, so just multiple documents concatenated.
    public static func instantiateAll(fromData data: [UInt8]) throws -> [Document] {
        var currentDataIndex = 0
        var documents = [Document]()
        while currentDataIndex < data.count {
            var consumedBytes = 0
            documents.append(try Document(data: Array(data[currentDataIndex..<data.count]), consumedBytes: &consumedBytes))
            
            guard consumedBytes > 0 else {
                throw DeserializationError.ParseError
            }
            
            currentDataIndex += consumedBytes
        }
        return documents
    }
    
    public static func findDocuments(data: [UInt8]) -> (consumed: Int, found: Int) {
        var position = data.startIndex
        var found = 0
        
        while position < data.endIndex {
            guard data.endIndex - position >= 5 else {
                return (consumed: position, found: found)
            }
            
            // The first four bytes of a document represent the total size of the document
            let lengthBytes = Array(data[position..<position+4])
            let documentLength = Int(Int32(littleEndian: UnsafePointer<Int32>(lengthBytes).pointee))
            
            guard data.count >= position + documentLength else {
                return (consumed: position, found: found)
            }
            
            guard documentLength >= 5 else {
                return (consumed: position, found: found)
            }
            
            guard data[position + documentLength - 1] == 0x00 else {
                return (consumed: position, found: found)
            }
            
            position += documentLength
            found += 1
        }
        
        return (consumed: position, found: found)
    }
}

extension Document {
    /// Returns true if this Document is an array and false otherwise.
    func validatesAsArray() -> Bool {
        var current = -1
        for (key, _) in self.elements {
            guard let index = Int(key) else {
                return false
            }
            
            if current == index-1 {
                current += 1
            } else {
                return false
            }
        }
        return true
    }
}

//extension Document : CustomStringConvertible {
//    /// Returns the description of all elements in this document. Not ordered correctly.
//    public var description: String {
//        return self.bsonDescription
//    }
//}
//
//extension Document : CustomDebugStringConvertible {
//    public var debugDescription: String {
//        return self.bsonDescription
//    }
//}

extension Document : Equatable {}
public func ==(left: Document, right: Document) -> Bool {
    return left.bsonData == right.bsonData
}
