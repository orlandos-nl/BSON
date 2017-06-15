//
//  Encoding.swift
//  BSON
//
//  Created by Robbert Brandsma on 13/06/2017.
//

import Foundation

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
        return _BSONSingleValueContainer(encoder: self)
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

fileprivate struct _BSONSingleValueContainer : SingleValueEncodingContainer {
    let encoder: _BSONEncoder
    
    mutating func encodeNil() throws {
        encoder.target.primitive = nil
    }
    
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

