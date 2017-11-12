//
//  Primitive.swift
//  BSON
//
//  Created by Robbert Brandsma on 18-04-16.
//
//

import Foundation

func escape(_ string: String) -> String {
    var string = string
    
    string = string.replacingOccurrences(of: "\\", with: "\\\\")
    string = string.replacingOccurrences(of: "\"", with: "\\\"")
    string = string.replacingOccurrences(of: "\u{8}", with: "\\b")
    string = string.replacingOccurrences(of: "\u{c}", with: "\\f")
    string = string.replacingOccurrences(of: "\n", with: "\\n")
    string = string.replacingOccurrences(of: "\r", with: "\\r")
    string = string.replacingOccurrences(of: "\t", with: "\\t")
    
    return string
}

/// Do not extend. BSON internals
public protocol Primitive: Codable {
    var typeIdentifier: UInt8 { get }
    
    func makeBinary() -> Data
}

func regexOptions(fromString s: String) -> NSRegularExpression.Options {
    var options: NSRegularExpression.Options = []
    
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

public struct Timestamp: Primitive, Equatable {
    public static func ==(lhs: Timestamp, rhs: Timestamp) -> Bool {
        return lhs.increment == rhs.increment && lhs.timestamp == rhs.timestamp
    }
    
    public var timestamp: Int32
    public var increment: Int32
    
    public var typeIdentifier: UInt8 {
        return 0x11
    }
    
    public init(increment: Int32, timestamp: Int32) {
        self.timestamp = timestamp
        self.increment = increment
    }
    
    public func makeBinary() -> Data {
        return increment.makeBinary() + timestamp.makeBinary()
    }
}

extension Data : Primitive {
    public var typeIdentifier: UInt8 {
        return 0x05
    }
    
    public func makeBinary() -> Data {
        return Binary(data: self, withSubtype: .generic).makeBinary()
    }
}

public struct Binary: Primitive {
    /// All binary subtypes
    public enum Subtype {
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
        
        /// System reserved
        case systemReserved(UInt8)
        
        /// The raw Byte value
        public var rawValue : UInt8 {
            switch self {
            case .generic: return 0x00
            case .function: return 0x01
            case .binaryOld: return 0x02
            case .uuidOld: return 0x03
            case .uuid: return 0x04
            case .md5: return 0x05
            case .systemReserved(let value): return value
            case .userDefined(let value): return value
            }
        }
        
        /// Creates a `BinarySubtype` from an `Byte`
        public init(rawValue: UInt8) {
            switch rawValue {
            case 0x00: self = .generic
            case 0x01: self = .function
            case 0x02: self = .binaryOld
            case 0x03: self = .uuidOld
            case 0x04: self = .uuid
            case 0x05: self = .md5
            case 0x80...0xFF: self = .userDefined(rawValue)
            default: self = .systemReserved(rawValue)
            }
        }
    }
    
    public var data: Data
    public var subtype: Subtype
    
    public init(data: Data, withSubtype subtype: Subtype) {
        self.data = data
        self.subtype = subtype
    }
    
    public var typeIdentifier: UInt8 {
        return 0x05
    }
    
    public func makeBinary() -> Data {
        guard data.count <= Int(Int32.max) else {
            // 4 bytes for the length and a null terminator byte
            return Data([0, 0, 0, 0, 0])
        }
        
        let length = Int32(data.count)
        
        return length.makeBytes() + [subtype.rawValue] + data
    }
}

extension Binary : Equatable {
    public static func ==(lhs: Binary, rhs: Binary) -> Bool {
        return lhs.data == rhs.data && lhs.subtype == rhs.subtype
    }
}

extension Binary.Subtype : Equatable {
    public static func ==(lhs: Binary.Subtype, rhs: Binary.Subtype) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
}

struct Null: Primitive {
    public var typeIdentifier: UInt8 {
        return 0x0A
    }
    
    public func makeBinary() -> Data {
        return Data()
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encodeNil()
    }
    
    public init(from decoder: Decoder) throws {
        _ = try decoder.singleValueContainer().decodeNil()
    }
    
    public init() {}
}

public struct JavascriptCode: Primitive {
    public var code: String
    public var scope: Document?
    
    public var typeIdentifier: UInt8 {
        return self.scope == nil ? 0x0D : 0x0F
    }
    
    public func makeBinary() -> Data {
        if let scope = scope {
            let data = self.code.makeBinary() + Data(scope.bytes)
            return Int32(data.count + 4).makeBytes() + data
        } else {
            return self.code.makeBinary()
        }
    }
    
    public init(code: String, withScope scope: Document? = nil) {
        self.code = code
        self.scope = scope
    }
}

extension Bool : Primitive {
    public var typeIdentifier: UInt8 {
        return 0x08
    }
    
    public func makeBinary() -> Data {
        return self ? Data([0x01]) : Data([0x00])
    }
}

extension Double : Primitive {
    public var typeIdentifier: UInt8 {
        return 0x01
    }
    
    public func makeBinary() -> Data {
        return self.makeBytes()
    }
}

extension Int32 : Primitive {
    public var typeIdentifier: UInt8 {
        return 0x10
    }
    
    public func makeBinary() -> Data {
        return self.makeBytes()
    }
}

extension Int : Primitive {
    public var typeIdentifier: UInt8 {
        return 0x12
    }
    
    public func makeBinary() -> Data {
        return self.makeBytes()
    }
}

internal let isoDateFormatter: DateFormatter = {
    let fmt = DateFormatter()
    fmt.locale = Locale(identifier: "en_US_POSIX")
    fmt.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
    return fmt
}()

extension Date : Primitive {
    public func makeBinary() -> Data {
        let integer = Int(self.timeIntervalSince1970 * 1000)
        return integer.makeBytes()
    }
    
    public var typeIdentifier: UInt8 {
        return 0x09
    }
}

extension String : Primitive {
    public func makeBinary() -> Data {
        var byteArray = Int32(self.utf8.count + 1).makeBytes()
        byteArray.append(contentsOf: self.utf8)
        byteArray.append(0x00)
        return byteArray
    }
    
    public var typeIdentifier: UInt8 {
        return 0x02
    }
}

extension Document: Primitive {
    public init<S>(sequence: S) where S : Sequence, S.Iterator.Element == SupportedValue {
        var doc = Document()
        
        for (key, value) in sequence {
            doc[key] = value
        }
        
        self = doc
    }
    
    public typealias ObjectKey = String
    public typealias ObjectValue = Primitive
    public typealias SupportedValue = (String, Primitive)
    public typealias SequenceType = Document
    
    public var typeIdentifier: UInt8 {
        return self.isArray ?? validatesAsArray() ? 0x04 : 0x03
    }
    
    public func makeBinary() -> Data {
        return self.bytes
    }
}

extension ObjectId : Primitive {
    public var typeIdentifier: UInt8 {
        return 0x07
    }
    
    public func makeBinary() -> Data {
        return self._storage
    }
}

public struct MinKey: Primitive {
    public init() {}
    
    public var typeIdentifier: UInt8 {
        return 0xFF
    }
    
    public func makeBinary() -> Data {
        return Data()
    }
}

public struct MaxKey: Primitive {
    public init() {}
    
    public var typeIdentifier: UInt8 {
        return 0x7F
    }
    
    public func makeBinary() -> Data {
        return Data()
    }
}

extension RegularExpression: Primitive {
    public var typeIdentifier: UInt8 {
        return 0x0B
    }
    
    public func encode(to encoder: Encoder) throws {
        try self.pattern.encode(to: encoder)
    }
    
    public init(from decoder: Decoder) throws {
        self.pattern = try decoder.singleValueContainer().decode(String.self)
        self.options = []
    }
    
    public func makeBinary() -> Data {
        return Data(self.pattern.utf8 + [0x00] + makeOptions().utf8 + [0x00])
    }
    
    func makeOptions() -> String {
        var options = ""
        
        if self.options.contains(.caseInsensitive) {
            options.append("i")
        }
        
        if self.options.contains(.anchorsMatchLines) {
            options.append("m")
        }
        
        if self.options.contains(.allowCommentsAndWhitespace) {
            options.append("x")
        }
        
        if self.options.contains(.dotMatchesLineSeparators) {
            options.append("s")
        }
        
        return options
    }
}
