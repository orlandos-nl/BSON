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
        
        return encoder.storage
    }
    
}

fileprivate class _BSONEncoder : Encoder {
    var storage: Document
    
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
        fatalError()
    }
    
    init(codingPath: [CodingKey?] = []) {
        self.codingPath = codingPath
        self.storage = Document()
    }
}

fileprivate class _NestedBSONEncoder : _BSONEncoder {
    private let parent: _BSONEncoder
    private let parentKey: String
    
    override var storage: Document {
        get {
            return parent.storage[parentKey] as? Document ?? Document()
        }
        set {
            parent.storage[parentKey] = newValue
        }
    }
    
    init(parent: _BSONEncoder, parentKey: String, codingPath: [CodingKey?] = []) {
        self.parent = parent
        self.parentKey = parentKey
        super.init(codingPath: codingPath)
    }
}

fileprivate struct _BSONKeyedEncodingContainer<K : CodingKey> : KeyedEncodingContainerProtocol {
    let encoder: _BSONEncoder
    
    var codingPath: [CodingKey?]
    
    func encode(_ value: Bool, forKey key: K) throws { encoder.storage[key.stringValue] = value }
    func encode(_ value: Int, forKey key: K) throws { encoder.storage[key.stringValue] = value }
    func encode(_ value: Int8, forKey key: K) throws { encoder.storage[key.stringValue] = Int32(value) }
    func encode(_ value: Int16, forKey key: K) throws { encoder.storage[key.stringValue] = Int32(value) }
    func encode(_ value: Int32, forKey key: K) throws { encoder.storage[key.stringValue] = value }
    func encode(_ value: Int64, forKey key: K) throws { encoder.storage[key.stringValue] = Int(value) }
    func encode(_ value: UInt8, forKey key: K) throws { encoder.storage[key.stringValue] = Int32(value) }
    func encode(_ value: UInt16, forKey key: K) throws { encoder.storage[key.stringValue] = Int32(value) }
    func encode(_ value: UInt32, forKey key: K) throws { encoder.storage[key.stringValue] = Int(value) }
    func encode(_ value: Float, forKey key: K) throws { encoder.storage[key.stringValue] = Double(value) }
    func encode(_ value: Double, forKey key: K) throws { encoder.storage[key.stringValue] = value }
    func encode(_ value: String, forKey key: K) throws { encoder.storage[key.stringValue] = value }
    
    func encode<T>(_ value: T, forKey key: K) throws where T : Encodable {
        print(value)
        fatalError("Unimplemented")
    }
    
    mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: K) -> KeyedEncodingContainer<NestedKey> {
        let nestedEncoder = _NestedBSONEncoder(parent: encoder, parentKey: key.stringValue)
        return nestedEncoder.container(keyedBy: NestedKey.self)
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
    
    func encode(_ value: UInt, forKey key: K) throws {
        guard value < Int.max else {
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: codingPath, debugDescription: "Value exceeds \(Int.max) which is the BSON Int limit"))
        }
        
        encoder.storage[key.stringValue] = Int(value)
    }
    
    func encode(_ value: UInt64, forKey key: K) throws {
        // BSON only supports 64 bit platforms where UInt64 is the same size as Int64
        try encode(UInt(value), forKey: key)
    }
    
    typealias Key = K
    
}

