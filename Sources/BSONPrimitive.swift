//
//  BSONPrimitive.swift
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
public protocol BSONPrimitive {
    var typeIdentifier: UInt8 { get }
    
    func makeBSONBinary() -> [UInt8]
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

public struct Timestamp: BSONPrimitive, Equatable {
    public static func ==(lhs: Timestamp, rhs: Timestamp) -> Bool {
        return lhs.increment == rhs.increment && lhs.timestamp == rhs.timestamp
    }
    
    var timestamp: Int32
    var increment: Int32
    
    public var typeIdentifier: UInt8 {
        return 0x11
    }
    
    public init(increment: Int32, timestamp: Int32) {
        self.timestamp = timestamp
        self.increment = increment
    }
    
    public func makeBSONBinary() -> [UInt8] {
        return increment.makeBytes() + timestamp.makeBytes()
    }
}

public struct Binary: BSONPrimitive {
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
        
        /// The raw UInt8 value
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
        
        /// Creates a `BinarySubtype` from an `UInt8`
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
    
    public init(data: [UInt8], withSubtype subtype: Subtype) {
        self.data = Data(bytes: data)
        self.subtype = subtype
    }
    
    public func makeBytes() -> [UInt8] {
        var data = [UInt8](repeating: 0, count: self.data.count)
        
        self.data.copyBytes(to: &data, count: data.count)
        
        return data
    }
    
    public var typeIdentifier: UInt8 {
        return 0x05
    }
    
    public func makeBSONBinary() -> [UInt8] {
        guard data.count < Int(Int32.max) else {
            // 4 bytes for the length and a null terminator byte
            return [0, 0, 0, 0, 0]
        }
        
        let length = Int32(data.count)
        return length.makeBytes() + [subtype.rawValue] + data
    }
}

public struct Null: BSONPrimitive {
    public var typeIdentifier: UInt8 {
        return 0x0A
    }

    public init() {}
    
    public func makeBSONBinary() -> [UInt8] {
        return []
    }
}

public struct JavascriptCode: BSONPrimitive {
    public var code: String
    public var scope: Document?
    
    public var typeIdentifier: UInt8 {
        return self.scope == nil ? 0x0D : 0x0F
    }
    
    public func makeBSONBinary() -> [UInt8] {
        if let scope = scope {
            let data = self.code.bytes + scope.bytes
            return Int32(data.count + 4).makeBytes() + data
        } else {
            return self.code.bytes
        }
    }
    
    public init(_ code: String, withScope scope: Document? = nil) {
        self.code = code
        self.scope = scope
    }
}

extension Bool : BSONPrimitive {
    public var typeIdentifier: UInt8 {
        return 0x08
    }
    
    public func makeBSONBinary() -> [UInt8] {
        return self ? [0x01] : [0x00]
    }
}

extension Double : BSONPrimitive {
    public var typeIdentifier: UInt8 {
        return 0x01
    }

    public func makeBSONBinary() -> [UInt8] {
        return self.makeBytes()
    }
}

extension Int32 : BSONPrimitive {
    public var typeIdentifier: UInt8 {
        return 0x10
    }
    
    public func makeBSONBinary() -> [UInt8] {
        return self.makeBytes()
    }
}

extension Int : BSONPrimitive {
    public var typeIdentifier: UInt8 {
        return 0x12
    }
    
    public func makeBSONBinary() -> [UInt8] {
        return self.makeBytes()
    }
}

internal let isoDateFormatter: DateFormatter = {
    let fmt = DateFormatter()
    fmt.locale = Locale(identifier: "en_US_POSIX")
    fmt.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
    return fmt
}()

extension Date : BSONPrimitive {
    public func makeBSONBinary() -> [UInt8] {
        let integer = Int(self.timeIntervalSince1970 * 1000)
        return integer.makeBytes()
    }

    public var typeIdentifier: UInt8 {
        return 0x09
    }
}

extension String : BSONPrimitive {
    public func makeBSONBinary() -> [UInt8] {
        var byteArray = Int32(self.utf8.count + 1).makeBytes()
        byteArray.append(contentsOf: self.utf8)
        byteArray.append(0x00)
        return byteArray
    }

    public var typeIdentifier: UInt8 {
        return 0x02
    }
}

extension StaticString : BSONPrimitive {
    public func makeBSONBinary() -> [UInt8] {
        return self.withUTF8Buffer {
            var data = [UInt8](repeating: 0, count: self.utf8CodeUnitCount + 1)
            memcpy(&data, $0.baseAddress!, self.utf8CodeUnitCount)
            return data
        }
    }
    
    public var typeIdentifier: UInt8 {
        return 0x02
    }
}

extension Document : BSONPrimitive {
    public var typeIdentifier: UInt8 {
        return isArray ? 0x04 : 0x03
    }
    
    public func makeBSONBinary() -> [UInt8] {
        return self.bytes
    }
 }

extension ObjectId : BSONPrimitive {
    public var typeIdentifier: UInt8 {
        return 0x07
    }
    
    public func makeBSONBinary() -> [UInt8] {
        return self._storage
    }
}

struct MinKey: BSONPrimitive {
    init() {}
    
    var typeIdentifier: UInt8 {
        return 0xFF
    }
    
    func makeBSONBinary() -> [UInt8] {
        return []
    }
}

struct MaxKey: BSONPrimitive {
    init() {}
    
    var typeIdentifier: UInt8 {
        return 0x7F
    }
    
    func makeBSONBinary() -> [UInt8] {
        return []
    }
}

extension RegularExpression : BSONPrimitive {
    public var typeIdentifier: UInt8 {
        return 0x0B
    }
    
    public func makeBSONBinary() -> [UInt8] {
        return self.pattern.cStringBytes + makeOptions().cStringBytes
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
