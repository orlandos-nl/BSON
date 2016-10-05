//
//  Value.swift
//  BSON
//
//  Created by Robbert Brandsma on 18-04-16.
//
//

import Foundation

/// All binary subtypes
public enum BinarySubtype {
    /// The default subtype. Nothing special
    case generic
    
    /// A function
    case function
    
    /// Old binary subtype
    case binaryOld
    
    /// Old UUID Subtype
    case uuidOld
    
    /// UUID
    case uuid
    
    /// MD5 hash
    case md5
    
    /// Custom
    case userDefined(UInt8)
    
    /// The raw UInt8 value
    public var rawValue : UInt8 {
        switch self {
        case .generic: return 0x00
        case .function: return 0x01
        case .binaryOld: return 0x02
        case .uuidOld: return 0x03
        case .uuid: return 0x04
        case .md5: return 0x05
        case .userDefined(let value): return value
        }
    }
    
    /// Creates a `BinarySubtype` from an `UInt8`
    public init(rawValue: UInt8) {
        switch rawValue {
        case 0x00: self = .generic
        case 0x01: self = .function
        case 0x02: self = .binaryOld
        case 0x03: self = .uuidOld
        case 0x04: self = .uuid
        case 0x05: self = .md5
        default: self = .userDefined(rawValue)
        }
    }
}


/// A single BSON value.
///
/// BSON values can be compared using the `==`, `===`, `<`, `>`, `<=` and `>=` operators. When comparing values, the sort order as specified in the [MongoDB documentation](https://docs.mongodb.com/manual/reference/bson-types/) is used.
///
/// - double:                             64 bit binary floating point
/// - string:                             UTF-8 string
/// - document:                           Embedded document
/// - array:                              Array
/// - binary:                             Binary data
/// - objectId:                           [ObjectId](http://dochub.mongodb.org/core/objectids)
/// - boolean:                            Boolean (true or false)
/// - dateTime:                           UTC DateTime
/// - null:                               Null value
/// - regularExpression:                  Regular expression with regex pattern and options string. Options are identified by characters, which must be stored in alphabetical order. Valid options are 'i' for case insensitive matching, 'm' for multiline matching, 'x' for verbose mode, 'l' to make \w, \W, etc. locale dependent, 's' for dotall mode ('.' matches everything), and 'u' to make \w, \W, etc. match unicode.
/// - javascriptCode:                     JavaScript code
/// - javascriptCodeWithScope:            JavaScript code w/ scope
/// - int32:                              32-bit integer
/// - timestamp:                          MongoBD internal timestamp type
/// - int64:                              64-bit integer
/// - minKey:                             Internal MongoDB type with lowest sort order.
/// - maxKey:                             Internal MongoDB type with highest sort order.
/// - nothing:                            Internal OpenKitten BSON type to indicate that a value is not present.
public enum Value {
    /// Double precision floating point
    case double(Double)
    
    /// -
    case string(String)
    
    /// Dictionary-like Document
    case document(Document)
    
    /// Array-like Document
    case array(Document)
    
    /// Binary data with an identification subtype
    case binary(subtype: BinarySubtype, data: [UInt8])
    
    /// Unique identifier
    case objectId(ObjectId)
    
    /// -
    case boolean(Bool)
    
    /// `Date`
    case dateTime(Date)
    
    /// NULL
    case null
    
    /// Regex, primarily used for MongoDB comparison
    case regularExpression(pattern: String, options: String)
    
    /// JavaScript Code, used for functions in MongoDB
    case javascriptCode(String)
    
    /// JavaScript Code in a scope, used for functions in MongoDB
    case javascriptCodeWithScope(code: String, scope: Document)
    
    /// -
    case int32(Int32)
    
    /// UNIX Epoch time with increment
    case timestamp(stamp: Int32, increment: Int32)
    
    /// -
    case int64(Int64)
    
    /// -
    case minKey
    
    /// -
    case maxKey
    
    /// Used by this BSON library to indicate there is no resulting value.
    ///
    /// Primarily used to allow recursive subscripting without `?`
    case nothing
    
    internal var typeIdentifier : UInt8 {
        switch self {
        case .double: return 0x01
        case .string: return 0x02
        case .document: return 0x03
        case .array: return 0x04
        case .binary: return 0x05
        case .objectId: return 0x07
        case .boolean: return 0x08
        case .dateTime: return 0x09
        case .null: return 0x0A
        case .regularExpression: return 0x0B
        case .javascriptCode: return 0x0D
        case .javascriptCodeWithScope: return 0x0F
        case .int32: return 0x10
        case .timestamp: return 0x11
        case .int64: return 0x12
        case .minKey: return 0xFF
        case .maxKey: return 0x7F
        case .nothing: return 0x0A
        }
    }
    
    public var rawValue: ValueConvertible? {
        func regexOptions(fromString s: String) -> RegularExpression.Options {
            var options: RegularExpression.Options = []
            
            if s.contains("i") {
                options.update(with: .caseInsensitive)
            }
            
            if s.contains("m") {
                options.update(with: .anchorsMatchLines)
            }
            
            if s.contains("x") {
                options.update(with: .allowCommentsAndWhitespace)
            }
            
            if s.contains("s") {
                options.update(with: .dotMatchesLineSeparators)
            }
            
            return options
        }
        
        switch self {
        case .double(let value): return value
        case .string(let value): return value
        case .document(let value): return value
        case .array(let value): return value
        case .binary(_, let value): return Data(bytes: value)
        case .objectId(let value): return value
        case .boolean(let value): return value
        case .dateTime(let value): return value
        case .regularExpression(let pattern, let options):
            do {
                return try RegularExpression(pattern: pattern, options: regexOptions(fromString: options))
            } catch {
                return nil
            }
        case .javascriptCode(let value): return value
        case .int32(let value): return value
        case .timestamp(let stamp, _): return Date(timeIntervalSince1970: Double(stamp))
        case .int64(let value): return value
            
        // TODO: Unsupported
        case .null: return nil
        case .minKey: return nil
        case .maxKey: return nil
        case .javascriptCodeWithScope(_, _): return nil
        case .nothing: return nil
        }
    }
}

extension Value : Comparable {}

public func <(lhs: Value, rhs: Value) -> Bool {
    let numberOrder = 2
    
    func getTypeOrder(of value: Value) -> Int {
        switch value {
        case .minKey: return -200
        case .null, .nothing: return 1
        case .int32, .int64, .double: return numberOrder
        case .string: return 3
        case .document: return 4
        case .array: return 5
        case .binary: return 6
        case .objectId: return 7
        case .boolean: return 8
        case .dateTime: return 9
        case .timestamp: return 10
        case .regularExpression: return 11
        case .javascriptCode, .javascriptCodeWithScope: return 100 // not documented!
        case .maxKey: return 200
        }
    }
    
    let order = (lhs: getTypeOrder(of: lhs), rhs: getTypeOrder(of: rhs))
    if order.lhs != order.rhs { // different type orders
        return order.lhs < order.rhs
    }
    
    switch (order.lhs, lhs, rhs) {
    case (_, .double(let dl), .double(let dr)): // doubles
        return dl < dr
    case (_, .int64(let il), .int64(let ir)):
        return il < ir
    case (numberOrder, _, _): // other combinations, compare as double
        return lhs.double < rhs.double
    case (_, .binary(let stl, let dtl), .binary(let str, let dtr)):
        // first, compare the length or size of the data
        if dtl.count != dtr.count {
            return dtl.count < dtr.count
        }
        
        // then, compare the subtype
        if stl.rawValue != str.rawValue {
            return stl.rawValue < str.rawValue
        }
        
        // finally, a byte-by-byte comparison
        for i in 0..<dtl.count { // both have the same length so this is safe
            let bytel = dtl[i]
            let byter = dtr[i]
            if bytel != byter {
                return bytel < byter
            }
        }
        
        // they are equal
        return false
    default:
        // TODO: Implement other comparisons as defined here: https://docs.mongodb.com/manual/reference/bson-types/
        return false
    }
}
