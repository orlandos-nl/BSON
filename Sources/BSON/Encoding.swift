//
//  Encoding.swift
//  BSON
//
//  Created by Robbert Brandsma on 13/06/2017.
//

import Foundation

// MARK: - Encoding

extension ObjectId : Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.hexString)
    }
}

public class BSONEncoder {
    
    public init() {}
    
    public func encode<T : Encodable>(_ value: T) throws -> Document {
        let encoder = _BSONEncoder()
        try value.encode(to: encoder)
        
        return encoder.target.document
    }
    
}

fileprivate class _BSONEncoder : Encoder {
    enum Target {
        case document(Document)
        case primitive(get: () -> Primitive?, set: (Primitive?) -> ())
        
        var document: Document {
            get {
                switch self {
                case .document(let doc): return doc
                case .primitive(let get, _): return get() as? Document ?? Document()
                }
            }
            set {
                switch self {
                case .document: self = .document(newValue)
                case .primitive(_, let set): set(newValue)
                }
            }
        }
        
        var primitive: Primitive? {
            get {
                switch self {
                case .document(let doc): return doc
                case .primitive(let get, _): return get()
                }
            }
            set {
                switch self {
                case .document: self = .document(newValue as! Document)
                case .primitive(_, let set): set(newValue)
                }
            }
        }
    }
    var target: Target
    
    var codingPath: [CodingKey?]
    var userInfo: [CodingUserInfoKey : Any] = [:]
    
    func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> {
        let container = _BSONKeyedEncodingContainer<Key>(encoder: self, codingPath: codingPath)
        return KeyedEncodingContainer(container)
    }
    
    func unkeyedContainer() -> UnkeyedEncodingContainer {
        fatalError()
    }
    
    func singleValueContainer() -> SingleValueEncodingContainer {
        return _BSONSingleValueEncodingContainer(encoder: self)
    }
    
    init(codingPath: [CodingKey?] = [], target: Target = .document([:])) {
        self.codingPath = codingPath
        self.target = target
    }
    
    // MARK: - Coding Path Operations
    /// Performs the given closure with the given key pushed onto the end of the current coding path.
    ///
    /// - parameter key: The key to push. May be nil for unkeyed containers.
    /// - parameter work: The work to perform with the key in the path.
    func with<T>(pushedKey key: CodingKey?, _ work: () throws -> T) rethrows -> T {
        self.codingPath.append(key)
        let ret: T = try work()
        self.codingPath.removeLast()
        return ret
    }
    
    // MARK: - Value conversion
    func convert(_ value: Bool) throws -> Primitive { return value }
    func convert(_ value: Int) throws -> Primitive { return value }
    func convert(_ value: Int8) throws -> Primitive { return Int32(value) }
    func convert(_ value: Int16) throws -> Primitive { return Int32(value) }
    func convert(_ value: Int32) throws -> Primitive { return value }
    func convert(_ value: Int64) throws -> Primitive { return Int(value) }
    func convert(_ value: UInt8) throws -> Primitive { return Int32(value) }
    func convert(_ value: UInt16) throws -> Primitive { return Int32(value) }
    func convert(_ value: UInt32) throws -> Primitive { return Int(value) }
    func convert(_ value: Float) throws -> Primitive { return Double(value) }
    func convert(_ value: Double) throws -> Primitive { return value }
    func convert(_ value: String) throws -> Primitive { return value }
    func convert(_ value: UInt) throws -> Primitive {
        guard value < Int.max else {
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: codingPath, debugDescription: "Value exceeds \(Int.max) which is the BSON Int limit"))
        }
        
        return Int(value)
    }
    func convert(_ value: UInt64) throws -> Primitive {
        // BSON only supports 64 bit platforms where UInt64 is the same size as Int64
        return try convert(UInt(value))
    }
}

fileprivate struct _BSONKeyedEncodingContainer<K : CodingKey> : KeyedEncodingContainerProtocol {
    let encoder: _BSONEncoder
    
    var codingPath: [CodingKey?]
    
    func encode<T>(_ value: T, forKey key: K) throws where T : Encodable {
        if let primitive = value as? Primitive {
            self.encoder.target.document[key.stringValue] = primitive
        } else {
            let encoder = _BSONEncoder(target: .primitive(get: { self.encoder.target.document[key.stringValue] }, set: { self.encoder.target.document[key.stringValue] = $0 }))
            try value.encode(to: encoder)
        }
    }
    
    func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: K) -> KeyedEncodingContainer<NestedKey> {
        let encoder = _BSONEncoder(target: .primitive(get: { self.encoder.target.document[key.stringValue] }, set: { self.encoder.target.document[key.stringValue] = $0 }))
        return encoder.container(keyedBy: keyType)
    }
    
    mutating func nestedUnkeyedContainer(forKey key: K) -> UnkeyedEncodingContainer {
        fatalError("Unimplemented")
    }
    
    mutating func superEncoder() -> Encoder {
        fatalError("Unimplemented")
    }
    
    mutating func superEncoder(forKey key: K) -> Encoder {
        fatalError("Unimplemented")
    }
    
    typealias Key = K
}

fileprivate struct _BSONSingleValueEncodingContainer : SingleValueEncodingContainer {
    let encoder: _BSONEncoder
    
    func encodeNil() throws { encoder.target.primitive = nil }
    func encode(_ value: Bool) throws { try encoder.target.primitive = encoder.convert(value) }
    func encode(_ value: Int) throws { try encoder.target.primitive = encoder.convert(value) }
    func encode(_ value: Int8) throws { try encoder.target.primitive = encoder.convert(value) }
    func encode(_ value: Int16) throws { try encoder.target.primitive = encoder.convert(value) }
    func encode(_ value: Int32) throws { try encoder.target.primitive = encoder.convert(value) }
    func encode(_ value: Int64) throws { try encoder.target.primitive = encoder.convert(value) }
    func encode(_ value: UInt8) throws { try encoder.target.primitive = encoder.convert(value) }
    func encode(_ value: UInt16) throws { try encoder.target.primitive = encoder.convert(value) }
    func encode(_ value: UInt32) throws { try encoder.target.primitive = encoder.convert(value) }
    func encode(_ value: Float) throws { try encoder.target.primitive = encoder.convert(value) }
    func encode(_ value: Double) throws { try encoder.target.primitive = encoder.convert(value) }
    func encode(_ value: String) throws { try encoder.target.primitive = encoder.convert(value) }
    func encode(_ value: UInt) throws { try encoder.target.primitive = encoder.convert(value) }
    func encode(_ value: UInt64) throws { try encoder.target.primitive = encoder.convert(value) }
        
    func encode<T>(_ value: T) throws where T : Encodable {
        // Encode BSON primitives directly
        if let primitive = value as? Primitive {
            encoder.target.primitive = primitive
        } else {
            try value.encode(to: encoder)
        }
    }
}

// MARK: - Decoding

extension ObjectId : Decodable {
    public init(from decoder: Decoder) throws {
        let singleValueContainer = try decoder.singleValueContainer()
        let string = try singleValueContainer.decode(String.self)
        self = try ObjectId(string)
    }
}

public class BSONDecoder {
    public func decode<T : Decodable>(_ type: T.Type, from document: Document) throws -> T {
        let decoder = _BSONDecoder(target: .document(document))
        return try T(from: decoder)
    }
    
    public init() {}
}

fileprivate func unwrap<T>(_ value: T?, codingPath: [CodingKey?]) throws -> T {
    guard let value = value else {
        throw DecodingError.valueNotFound(T.self, DecodingError.Context(codingPath: codingPath, debugDescription: "Value of type \(T.self) was not found"))
    }
    
    return value
}

fileprivate class _BSONDecoder : Decoder {
    enum Target {
        case document(Document)
        case primitive(get: () -> Primitive?)
        case storedPrimitive(Primitive?)
        
        var document: Document {
            get {
                switch self {
                case .document(let doc): return doc
                case .primitive(let get): return get() as? Document ?? Document()
                case .storedPrimitive(let val): return val as? Document ?? Document()
                }
            }
        }
        
        var primitive: Primitive? {
            get {
                switch self {
                case .document(let doc): return doc
                case .primitive(let get): return get()
                case .storedPrimitive(let val): return val
                }
            }
        }
    }
    let target: Target
    
    var codingPath: [CodingKey?] = []
    
    var userInfo: [CodingUserInfoKey : Any] = [:]
    
    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> {
        let container = _BSONKeyedDecodingContainer<Key>(decoder: self, codingPath: self.codingPath)
        return KeyedDecodingContainer(container)
    }
    
    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        fatalError("Unimplemented")
    }
    
    func singleValueContainer() throws -> SingleValueDecodingContainer {
        return _BSONSingleValueDecodingContainer(decoder: self)
    }
    
    init(target: Target) {
        self.target = target
    }
    
    /// Performs the given closure with the given key pushed onto the end of the current coding path.
    ///
    /// - parameter key: The key to push. May be nil for unkeyed containers.
    /// - parameter work: The work to perform with the key in the path.
    func with<T>(pushedKey key: CodingKey?, _ work: () throws -> T) rethrows -> T {
        self.codingPath.append(key)
        let ret: T = try work()
        self.codingPath.removeLast()
        return ret
    }
    
    // MARK: - Value conversion
    func unwrap<T : Primitive>(_ value: Primitive?) throws -> T? {
        guard let primitiveValue = value else {
            return nil
        }
        
        guard let tValue = primitiveValue as? T else {
            throw DecodingError.typeMismatch(T.self, DecodingError.Context(codingPath: codingPath, debugDescription: "Type mismatch - expected value of type \(T.self), found \(type(of: primitiveValue))"))
        }
        
        return tValue
    }
    
    func unwrap(_ value: Primitive?) throws -> Int32? {
        guard let primitiveValue = value else {
            return nil
        }
        
        switch primitiveValue {
        case let number as Int32:
            return number
        case let number as Int:
            guard number > Int32.min && number < Int32.max else {
                throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: codingPath, debugDescription: "BSON number <\(number)> does not fit in \(Int32.self)"))
            }
            return Int32(number) as Int32
        case let number as Double:
            guard number > Double(Int32.min) && number < Double(Int32.max) else {
                throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: codingPath, debugDescription: "BSON number <\(number)> does not fit in \(Int32.self)"))
            }
            return Int32(number) as Int32
        default:
            throw DecodingError.typeMismatch(Int32.self, DecodingError.Context(codingPath: codingPath, debugDescription: "Type mismatch - expected value of type \(Int32.self), found \(type(of: primitiveValue))"))
        }
    }
    
    func unwrap(_ value: Primitive?) throws -> Int? {
        guard let primitiveValue = value else {
            return nil
        }
        
        switch primitiveValue {
        case let number as Int32:
            return Int(number) as Int
        case let number as Int:
            return number
        case let number as Double:
            guard number > Double(Int.min) && number < Double(Int.max) else {
                throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: codingPath, debugDescription: "BSON number <\(number)> does not fit in \(Int.self)"))
            }
            return Int(number) as Int
        default:
            throw DecodingError.typeMismatch(Int.self, DecodingError.Context(codingPath: codingPath, debugDescription: "Type mismatch - expected value of type \(Int.self), found \(type(of: primitiveValue))"))
        }
    }
    
    func unwrap(_ value: Primitive?) throws -> Double? {
        guard let primitiveValue = value else {
            return nil
        }
        
        switch primitiveValue {
        case let number as Int32:
            return Double(number)
        case let number as Int:
            return Double(number)
        case let number as Double:
            return number
        default:
            throw DecodingError.typeMismatch(Double.self, DecodingError.Context(codingPath: codingPath, debugDescription: "Type mismatch - expected value of type \(Double.self), found \(type(of: primitiveValue))"))
        }
    }
    
    func unwrap(_ value: Primitive?) throws -> Bool? {
        guard let primitiveValue = value else {
            return nil
        }
        
        guard let bool = primitiveValue as? Bool else {
            throw DecodingError.typeMismatch(Bool.self, DecodingError.Context(codingPath: codingPath, debugDescription: "Type mismatch - expected value of type \(Bool.self), found \(type(of: primitiveValue))"))
        }
        
        return bool
    }
    
    func unwrap(_ value: Primitive?) throws -> Int8? {
        guard let number: Int32 = try unwrap(value) else { return nil }
        guard number > Int8.min && number < Int8.max else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: codingPath, debugDescription: "BSON number <\(number)> does not fit in \(Int8.self)"))
        }
        return Int8(number)
    }
    
    func unwrap(_ value: Primitive?) throws -> Int16? {
        guard let number: Int32 = try unwrap(value) else { return nil }
        guard number > Int16.min && number < Int16.max else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: codingPath, debugDescription: "BSON number <\(number)> does not fit in \(Int16.self)"))
        }
        return Int16(number)
    }
    
    func unwrap(_ value: Primitive?) throws -> Int64? {
        guard let number: Int = try unwrap(value) else { return nil }
        return Int64(number)
    }
    
    func unwrap(_ value: Primitive?) throws -> UInt8? {
        guard let number: Int32 = try unwrap(value) else { return nil }
        guard number > UInt8.min && number < UInt8.max else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: codingPath, debugDescription: "BSON number <\(number)> does not fit in \(UInt8.self)"))
        }
        return UInt8(number)
    }
    
    func unwrap(_ value: Primitive?) throws -> UInt16? {
        guard let number: Int32 = try unwrap(value) else { return nil }
        guard number > UInt16.min && number < UInt16.max else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: codingPath, debugDescription: "BSON number <\(number)> does not fit in \(UInt16.self)"))
        }
        return UInt16(number)
    }
    
    func unwrap(_ value: Primitive?) throws -> UInt32? {
        guard let number: Int = try unwrap(value) else { return nil }
        guard number > UInt32.min && number < UInt32.max else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: codingPath, debugDescription: "BSON number <\(number)> does not fit in \(UInt32.self)"))
        }
        return UInt32(number)
    }
    
    func unwrap(_ value: Primitive?) throws -> Float? {
        // TODO: Check losing precision like JSONEncoder
        guard let number: Double = try unwrap(value) else { return nil }
        return Float(number)
    }
    
    func unwrap(_ value: Primitive?) throws -> UInt? {
        guard let number: Int = try unwrap(value) else { return nil }
        guard number > UInt.max else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: codingPath, debugDescription: "BSON number <\(number)> does not fit in \(UInt.self)"))
        }
        return UInt(number)
    }
    
    func unwrap(_ value: Primitive?) throws -> UInt64? {
        guard let number: UInt = try unwrap(value) else { return nil}
        // BSON only supports 64 bit platforms where UInt64 is the same size as UInt
        return UInt64(number)
    }
    
    func decode<T>(_ value: Primitive?) throws -> T? where T : Decodable {
        guard let value = value else {
            return nil
        }
        
        if T.self == ObjectId.self {
            let id = try BSON.unwrap(unwrap(value), codingPath: codingPath) as ObjectId as! T
            return id
        }
        
        let decoder = _BSONDecoder(target: .storedPrimitive(value))
        return try T(from: decoder)
    }
}

fileprivate struct _BSONKeyedDecodingContainer<Key : CodingKey> : KeyedDecodingContainerProtocol {
    let decoder: _BSONDecoder
    
    var codingPath: [CodingKey?]
    
    var allKeys: [Key] {
        return decoder.target.document.keys.flatMap { Key(stringValue: $0) }
    }
    
    func contains(_ key: Key) -> Bool {
        print(key, ": ", decoder.target.document[key.stringValue] as Any)
        return decoder.target.document[key.stringValue] != nil
    }
    
    func decodeIfPresent(_ type: Bool.Type, forKey key: Key) throws -> Bool? {
        return try decoder.with(pushedKey: key) {
            return try decoder.unwrap(decoder.target.document[key.stringValue])
        }
    }
    
    func decodeIfPresent(_ type: Int.Type, forKey key: Key) throws -> Int? {
        return try decoder.with(pushedKey: key) {
            return try decoder.unwrap(decoder.target.document[key.stringValue])
        }
    }
    
    func decodeIfPresent(_ type: Int8.Type, forKey key: Key) throws -> Int8? {
        return try decoder.with(pushedKey: key) {
            return try decoder.unwrap(decoder.target.document[key.stringValue])
        }
    }
    
    func decodeIfPresent(_ type: Int16.Type, forKey key: Key) throws -> Int16? {
        return try decoder.with(pushedKey: key) {
            return try decoder.unwrap(decoder.target.document[key.stringValue])
        }
    }
    
    func decodeIfPresent(_ type: Int32.Type, forKey key: Key) throws -> Int32? {
        return try decoder.with(pushedKey: key) {
            return try decoder.unwrap(decoder.target.document[key.stringValue])
        }
    }
    
    func decodeIfPresent(_ type: Int64.Type, forKey key: Key) throws -> Int64? {
        return try decoder.with(pushedKey: key) {
            return try decoder.unwrap(decoder.target.document[key.stringValue])
        }
    }
    
    func decodeIfPresent(_ type: UInt.Type, forKey key: Key) throws -> UInt? {
        return try decoder.with(pushedKey: key) {
            return try decoder.unwrap(decoder.target.document[key.stringValue])
        }
    }
    
    func decodeIfPresent(_ type: UInt8.Type, forKey key: Key) throws -> UInt8? {
        return try decoder.with(pushedKey: key) {
            return try decoder.unwrap(decoder.target.document[key.stringValue])
        }
    }
    
    func decodeIfPresent(_ type: UInt16.Type, forKey key: Key) throws -> UInt16? {
        return try decoder.with(pushedKey: key) {
            return try decoder.unwrap(decoder.target.document[key.stringValue])
        }
    }
    
    func decodeIfPresent(_ type: UInt32.Type, forKey key: Key) throws -> UInt32? {
        return try decoder.with(pushedKey: key) {
            return try decoder.unwrap(decoder.target.document[key.stringValue])
        }
    }
    
    func decodeIfPresent(_ type: UInt64.Type, forKey key: Key) throws -> UInt64? {
        return try decoder.with(pushedKey: key) {
            return try decoder.unwrap(decoder.target.document[key.stringValue])
        }
    }
    
    func decodeIfPresent(_ type: Float.Type, forKey key: Key) throws -> Float? {
        return try decoder.with(pushedKey: key) {
            return try decoder.unwrap(decoder.target.document[key.stringValue])
        }
    }
    
    func decodeIfPresent(_ type: Double.Type, forKey key: Key) throws -> Double? {
        return try decoder.with(pushedKey: key) {
            return try decoder.unwrap(decoder.target.document[key.stringValue])
        }
    }
    
    func decodeIfPresent(_ type: String.Type, forKey key: Key) throws -> String? {
        return try decoder.with(pushedKey: key) {
            return try decoder.unwrap(decoder.target.document[key.stringValue])
        }
    }
    
    func decodeIfPresent<T>(_ type: T.Type, forKey key: Key) throws -> T? where T : Decodable {
        return try decoder.with(pushedKey: key) {
            return try decoder.decode(decoder.target.document[key.stringValue])
        }
    }
    
    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
        fatalError("Unimplemented")
    }
    
    func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
        fatalError("Unimplemented")
    }
    
    func superDecoder() throws -> Decoder {
        fatalError("Unimplemented")
    }
    
    func superDecoder(forKey key: Key) throws -> Decoder {
        fatalError("Unimplemented")
    }
}

fileprivate struct _BSONSingleValueDecodingContainer : SingleValueDecodingContainer {
    let decoder: _BSONDecoder
    
    private func unwrap<T>(_ value: T?) throws -> T {
        return try BSON.unwrap(value, codingPath: decoder.codingPath)
    }
    
    func decodeNil() -> Bool { return decoder.target.primitive == nil }
    func decode(_ type: Bool.Type) throws -> Bool { return try unwrap(decoder.unwrap(decoder.target.primitive)) }
    func decode(_ type: Int.Type) throws -> Int { return try unwrap(decoder.unwrap(decoder.target.primitive)) }
    func decode(_ type: Int8.Type) throws -> Int8 { return try unwrap(decoder.unwrap(decoder.target.primitive)) }
    func decode(_ type: Int16.Type) throws -> Int16 { return try unwrap(decoder.unwrap(decoder.target.primitive)) }
    func decode(_ type: Int32.Type) throws -> Int32 { return try unwrap(decoder.unwrap(decoder.target.primitive)) }
    func decode(_ type: Int64.Type) throws -> Int64 { return try unwrap(decoder.unwrap(decoder.target.primitive)) }
    func decode(_ type: UInt.Type) throws -> UInt { return try unwrap(decoder.unwrap(decoder.target.primitive)) }
    func decode(_ type: UInt8.Type) throws -> UInt8 { return try unwrap(decoder.unwrap(decoder.target.primitive)) }
    func decode(_ type: UInt16.Type) throws -> UInt16 { return try unwrap(decoder.unwrap(decoder.target.primitive)) }
    func decode(_ type: UInt32.Type) throws -> UInt32 { return try unwrap(decoder.unwrap(decoder.target.primitive)) }
    func decode(_ type: UInt64.Type) throws -> UInt64 { return try unwrap(decoder.unwrap(decoder.target.primitive)) }
    func decode(_ type: Float.Type) throws -> Float { return try unwrap(decoder.unwrap(decoder.target.primitive)) }
    func decode(_ type: Double.Type) throws -> Double { return try unwrap(decoder.unwrap(decoder.target.primitive)) }
    func decode(_ type: String.Type) throws -> String { return try unwrap(decoder.unwrap(decoder.target.primitive)) }
    func decode<T>(_ type: T.Type) throws -> T where T : Decodable { return try unwrap(decoder.decode(decoder.target.primitive)) }
    
}
