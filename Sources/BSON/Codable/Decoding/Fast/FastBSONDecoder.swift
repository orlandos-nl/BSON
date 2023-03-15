import Foundation

public struct FastBSONDecoder {
    public init() {}
    
    public func decode<D: Decodable, P: Primitive>(_ type: D.Type = D.self, from primitive: P) throws -> D {
        let decoder = _FastBSONDecoder(value: primitive)
        return try D.init(from: decoder)
    }
}

struct _FastBSONDecoder<P: Primitive>: Decoder {
    let value: P
    var userInfo = [CodingUserInfoKey : Any]()
    var codingPath: [CodingKey] { [] }
    
    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey, P == Document {
        KeyedDecodingContainer(_FastKeyedContainer<Key>(document: value))
    }
    
    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
        guard let value = value as? Document else {
            throw BSONTypeConversionError(from: value, to: Document.self)
        }
        
        return KeyedDecodingContainer(_FastKeyedContainer<Key>(document: value))
    }
    
    func singleValueContainer() throws -> SingleValueDecodingContainer {
        _FastSingleValueContainer(value: value)
    }
    
    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        guard let value = value as? Document else {
            throw BSONTypeConversionError(from: value, to: Document.self)
        }
        
        return _FastUnkeyedContainer(document: value, endIndex: value.count)
    }
}

struct _FastKeyedContainer<Key: CodingKey>: KeyedDecodingContainerProtocol {
    let document: Document
    var codingPath: [CodingKey] { [] }
    
    var allKeys: [Key] { document.keys.compactMap(Key.init) }
    
    func contains(_ key: Key) -> Bool {
        document.containsKey(key.stringValue)
    }
    
    func decode(_ type: Int.Type, forKey key: Key) throws -> Int {
        try decodeFixedWidthInteger(forKey: key)
    }
    
    func decode(_ type: Int8.Type, forKey key: Key) throws -> Int8 {
        try decodeFixedWidthInteger(forKey: key)
    }
    
    func decode(_ type: Int16.Type, forKey key: Key) throws -> Int16 {
        try decodeFixedWidthInteger(forKey: key)
    }
    
    func decode(_ type: Int32.Type, forKey key: Key) throws -> Int32 {
        try decodeFixedWidthInteger(forKey: key)
    }
    
    func decode(_ type: Int64.Type, forKey key: Key) throws -> Int64 {
        try decodeFixedWidthInteger(forKey: key)
    }
    
    func decode(_ type: UInt.Type, forKey key: Key) throws -> UInt {
        try decodeFixedWidthInteger(forKey: key)
    }
    
    func decode(_ type: UInt8.Type, forKey key: Key) throws -> UInt8 {
        try decodeFixedWidthInteger(forKey: key)
    }
    
    func decode(_ type: UInt16.Type, forKey key: Key) throws -> UInt16 {
        try decodeFixedWidthInteger(forKey: key)
    }
    
    func decode(_ type: UInt32.Type, forKey key: Key) throws -> UInt32 {
        try decodeFixedWidthInteger(forKey: key)
    }
    
    func decode(_ type: UInt64.Type, forKey key: Key) throws -> UInt64 {
        try decodeFixedWidthInteger(forKey: key)
    }
    
    @inline(__always)
    func decodeFixedWidthInteger<F: FixedWidthInteger>(_ type: F.Type = F.self, forKey key: Key) throws -> F {
        guard let (type, offset) = document.typeAndValueOffset(forKey: key.stringValue) else {
            throw BSONValueNotFound(type: F.self, path: codingPath.map(\.stringValue))
        }
        
        switch type {
        case .int32:
            guard
                let int: Int32 = document.storage.getInteger(at: offset, endianness: .little),
                int >= F.min,
                int <= F.max
            else {
                throw BSONTypeConversionError(from: type, to: F.self)
            }
            
            return F(int)
        case .int64:
            guard
                let int: _BSON64BitInteger = document.storage.getInteger(at: offset, endianness: .little),
                int >= F.min,
                int <= F.max
            else {
                throw BSONTypeConversionError(from: type, to: F.self)
            }
            
            return F(int)
        default:
            throw BSONValueNotFound(type: F.self, path: codingPath.map(\.stringValue))
        }
    }
    
    func decode(_ type: Bool.Type, forKey key: Key) throws -> Bool {
        guard
            let (type, offset) = document.typeAndValueOffset(forKey: key.stringValue),
            type == .boolean,
            let int: UInt8 = document.storage.getInteger(at: offset, endianness: .little)
        else {
            throw BSONValueNotFound(type: Bool.self, path: codingPath.map(\.stringValue))
        }
        
        return int == 0x01
    }
    
    func decode(_ type: String.Type, forKey key: Key) throws -> String {
        guard
            let (type, offset) = document.typeAndValueOffset(forKey: key.stringValue),
            type == .string,
            let string = document.storage.getBSONString(at: offset)
        else {
            throw BSONValueNotFound(type: String.self, path: codingPath.map(\.stringValue))
        }
        
        return string
    }
    
    func decode(_ type: Double.Type, forKey key: Key) throws -> Double {
        guard
            let (type, offset) = document.typeAndValueOffset(forKey: key.stringValue),
            type == .double,
            let double = document.storage.getDouble(at: offset)
        else {
            throw BSONValueNotFound(type: Double.self, path: codingPath.map(\.stringValue))
        }
        
        return double
    }
    
    func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T : Decodable {
        switch document[key.stringValue] {
        case let value as Double: // 0x01
            let decoder = _FastBSONDecoder(value: value)
            return try T.init(from: decoder)
        case let value as String: // 0x0
            let decoder = _FastBSONDecoder(value: value)
            return try T.init(from: decoder)
        case let value as Document: // 0x03 (embedded document) or 0x04 (array)
            let decoder = _FastBSONDecoder(value: value)
            return try T.init(from: decoder)
        case let value as Binary: // 0x05
            if T.self == Data.self {
                return value.data as! T
            }
            
            let decoder = _FastBSONDecoder(value: value)
            return try T.init(from: decoder)
            // 0x06 is deprecated
        case let value as ObjectId: // 0x07
            let decoder = _FastBSONDecoder(value: value)
            return try T.init(from: decoder)
        case let value as Bool: // 0x08
            let decoder = _FastBSONDecoder(value: value)
            return try T.init(from: decoder)
        case let value as Date: // 0x09
            if T.self == Date.self {
                return value as! T
            }
            
            let decoder = _FastBSONDecoder(value: value)
            return try T.init(from: decoder)
        case is Null: // 0x0A
            let decoder = _FastBSONDecoder(value: Null())
            return try T.init(from: decoder)
        case let value as RegularExpression: // 0x0B
            let decoder = _FastBSONDecoder(value: value)
            return try T.init(from: decoder)
            // 0x0C is deprecated (DBPointer)
            // 0x0E is deprecated (Symbol)
        case let value as Int32: // 0x10
            let decoder = _FastBSONDecoder(value: value)
            return try T.init(from: decoder)
        case let value as Timestamp:
            let decoder = _FastBSONDecoder(value: value)
            return try T.init(from: decoder)
        case let value as _BSON64BitInteger: // 0x12
            let decoder = _FastBSONDecoder(value: value)
            return try T.init(from: decoder)
        case let value as Decimal128:
            let decoder = _FastBSONDecoder(value: value)
            return try T.init(from: decoder)
        case is MaxKey: // 0x7F
            let decoder = _FastBSONDecoder(value: MaxKey())
            return try T.init(from: decoder)
        case is MinKey: // 0xFF
            let decoder = _FastBSONDecoder(value: MinKey())
            return try T.init(from: decoder)
        case let value as JavaScriptCode:
            let decoder = _FastBSONDecoder(value: value)
            return try T.init(from: decoder)
        case let value as JavaScriptCodeWithScope:
            let decoder = _FastBSONDecoder(value: value)
            return try T.init(from: decoder)
        default:
            throw BSONValueNotFound(type: Void.self, path: codingPath.map(\.stringValue))
        }
    }
    
    func decodeNil(forKey key: Key) throws -> Bool {
        guard let type = document.typeIdentifier(of: key.stringValue) else {
            return true
        }
        
        return type == .null
    }
    
    func decode(_ type: Float.Type, forKey key: Key) throws -> Float {
        guard
            let (type, offset) = document.typeAndValueOffset(forKey: key.stringValue),
            type == .double,
            let double = document.storage.getDouble(at: offset)
        else {
            throw BSONValueNotFound(type: Float.self, path: codingPath.map(\.stringValue))
        }
        
        return Float(double)
    }
    
    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
        guard
            let (type, offset) = document.typeAndValueOffset(forKey: key.stringValue),
            type == .document,
            let length = document.storage.getInteger(at: offset, endianness: .little, as: Int32.self),
            let slice = document.storage.getSlice(at: offset, length: numericCast(length))
        else {
            throw BSONValueNotFound(type: Document.self, path: codingPath.map(\.stringValue))
        }
        
        let nestedDocument = Document(buffer: slice, isArray: type == .array)
        return KeyedDecodingContainer(_FastKeyedContainer<NestedKey>(document: nestedDocument))
    }
    
    func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
        guard
            let (type, offset) = document.typeAndValueOffset(forKey: key.stringValue),
            type == .array,
            let length = document.storage.getInteger(at: offset, endianness: .little, as: Int32.self),
            let slice = document.storage.getSlice(at: offset, length: numericCast(length))
        else {
            throw BSONValueNotFound(type: Document.self, path: codingPath.map(\.stringValue))
        }
        
        let nestedDocument = Document(buffer: slice, isArray: type == .array)
        return _FastUnkeyedContainer(document: nestedDocument, endIndex: nestedDocument.count)
    }
    
    func superDecoder() throws -> Decoder {
        fatalError()
    }
    
    func superDecoder(forKey key: Key) throws -> Decoder {
        fatalError()
    }
}

struct _FastSingleValueContainer<P: Primitive>: SingleValueDecodingContainer, AnySingleValueBSONDecodingContainer {
    let value: P
    var codingPath: [CodingKey] { [] }
    
    func decodeNil() -> Bool {
        value is Null
    }
    
    func decodeObjectId() throws -> ObjectId where P == ObjectId {
        value
    }
    
    func decodeObjectId() throws -> ObjectId {
        guard let value = value as? ObjectId else {
            throw BSONValueNotFound(type: ObjectId.self, path: codingPath.map(\.stringValue))
        }
        
        return value
    }
    
    func decodeDocument() throws -> Document where P == Document {
        value
    }
    
    func decodeDocument() throws -> Document {
        guard let value = value as? Document else {
            throw BSONValueNotFound(type: Document.self, path: codingPath.map(\.stringValue))
        }
        
        return value
    }
    
    func decodeDecimal128() throws -> Decimal128 where P == Decimal128 {
        value
    }
    
    func decodeDecimal128() throws -> Decimal128 {
        guard let value = value as? Decimal128 else {
            throw BSONValueNotFound(type: Decimal128.self, path: codingPath.map(\.stringValue))
        }
        
        return value
    }
    
    func decodeBinary() throws -> Binary where P == Binary {
        value
    }
    
    func decodeBinary() throws -> Binary {
        guard let value = value as? Binary else {
            throw BSONValueNotFound(type: Binary.self, path: codingPath.map(\.stringValue))
        }
        
        return value
    }
    
    func decodeRegularExpression() throws -> RegularExpression where P == RegularExpression {
        value
    }
    
    func decodeRegularExpression() throws -> RegularExpression {
        guard let value = value as? RegularExpression else {
            throw BSONValueNotFound(type: RegularExpression.self, path: codingPath.map(\.stringValue))
        }
        
        return value
    }
    
    func decodeNull() throws -> Null where P == Null {
        value
    }
    
    func decodeNull() throws -> Null {
        guard value is Null else {
            throw BSONValueNotFound(type: Null.self, path: codingPath.map(\.stringValue))
        }
        
        return Null()
    }
    
    func decode(_ type: P.Type) throws -> P where P : Decodable {
        return value
    }
    
    func decode(_ type: Int.Type) throws -> Int {
        if let value = value as? Int {
            return value
        }
        
        throw BSONValueNotFound(type: Int.self, path: codingPath.map(\.stringValue))
    }
    
    func decode(_ type: Int8.Type) throws -> Int8 {
        try decodeFixedWidthInteger()
    }
    
    func decode(_ type: Int16.Type) throws -> Int16 {
        try decodeFixedWidthInteger()
    }
    
    func decode(_ type: Int32.Type) throws -> Int32 {
        if let value = value as? Int32 {
            return value
        }
        
        throw BSONValueNotFound(type: Int32.self, path: codingPath.map(\.stringValue))
    }
    
    func decode(_ type: Int64.Type) throws -> Int64 {
        if let value = value as? Int64 {
            return value
        }
        
        throw BSONValueNotFound(type: Int64.self, path: codingPath.map(\.stringValue))
    }
    
    func decode(_ type: UInt.Type) throws -> UInt {
        try decodeFixedWidthInteger()
    }
    
    func decode(_ type: UInt8.Type) throws -> UInt8 {
        try decodeFixedWidthInteger()
    }
    
    func decode(_ type: UInt16.Type) throws -> UInt16 {
        try decodeFixedWidthInteger()
    }
    
    func decode(_ type: UInt32.Type) throws -> UInt32 {
        try decodeFixedWidthInteger()
    }
    
    func decode(_ type: UInt64.Type) throws -> UInt64 {
        try decodeFixedWidthInteger()
    }
    
    func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
        if T.self == Date.self, let value = value as? Date {
            return value as! T
        } else if T.self == Data.self, let value = value as? Binary {
            return value.data as! T
        }
        
        let decoder = _FastBSONDecoder(value: value)
        return try T.init(from: decoder)
    }
    
    func decode(_ type: Float.Type) throws -> Float where P == Double {
        return Float(value)
    }
    
    func decode(_ type: Float.Type) throws -> Float {
        guard let double = value as? Double else {
            throw BSONValueNotFound(type: Float.self, path: codingPath.map(\.stringValue))
        }
        
        return Float(double)
    }
    
    func decode(_ type: Bool.Type) throws -> Bool where P == Bool {
        return value
    }
    
    func decode(_ type: Bool.Type) throws -> Bool {
        guard let value = value as? Bool else {
            throw BSONValueNotFound(type: Bool.self, path: codingPath.map(\.stringValue))
        }
        
        return value
    }
    
    func decode(_ type: String.Type) throws -> String where P == String {
        return value
    }
    
    func decode(_ type: String.Type) throws -> String {
        guard let value = value as? String else {
            throw BSONValueNotFound(type: String.self, path: codingPath.map(\.stringValue))
        }
        
        return value
    }
    
    func decode(_ type: Double.Type) throws -> Double where P == Double {
        return value
    }
    
    func decode(_ type: Double.Type) throws -> Double {
        guard let value = value as? Double else {
            throw BSONValueNotFound(type: Double.self, path: codingPath.map(\.stringValue))
        }
        
        return value
    }
    
    @inline(__always)
    func decodeFixedWidthInteger<F: FixedWidthInteger>(_ type: F.Type = F.self) throws -> F {
        switch value {
        case let int as F:
            return int
        case let int as Int32:
            guard int >= F.min, int <= F.max else {
                throw BSONTypeConversionError(from: int, to: F.self)
            }
            
            return F(int)
        case let int as _BSON64BitInteger:
            guard int >= F.min, int <= F.max else {
                throw BSONTypeConversionError(from: int, to: F.self)
            }
            
            return F(int)
        default:
            throw BSONValueNotFound(type: F.self, path: codingPath.map(\.stringValue))
        }
    }
}

struct _FastUnkeyedContainer: UnkeyedDecodingContainer {
    let document: Document
    var endIndex: Int
    var currentIndex: Int = 0
    var count: Int? { endIndex }
    var codingPath: [CodingKey] { [] }
    var isAtEnd: Bool { currentIndex >= endIndex }
    
    mutating func decodeNil() -> Bool {
        guard
            let (type, _) = document.typeAndValueOffset(at: currentIndex),
            type == .null
        else {
            return false
        }
        
        currentIndex += 1
        return true
    }
    
    mutating func decodeObjectId() throws -> ObjectId {
        guard
            let (type, offset) = document.typeAndValueOffset(at: currentIndex),
            type == .objectId,
            let objectId = document.storage.getObjectId(at: offset)
        else {
            throw BSONValueNotFound(type: ObjectId.self, path: codingPath.map(\.stringValue))
        }
        
        currentIndex += 1
        return objectId
    }
    
    mutating func decode(_ type: Bool.Type) throws -> Bool {
        guard
            let (type, offset) = document.typeAndValueOffset(at: currentIndex),
            type == .boolean,
            let bool: UInt8 = document.storage.getInteger(at: offset)
        else {
            throw BSONValueNotFound(type: Bool.self, path: codingPath.map(\.stringValue))
        }
        
        currentIndex += 1
        return bool == 0x01
    }
    
    mutating func decode(_ type: String.Type) throws -> String {
        guard
            let (type, offset) = document.typeAndValueOffset(at: currentIndex),
            type == .string,
            let string = document.storage.getBSONString(at: offset)
        else {
            throw BSONValueNotFound(type: String.self, path: codingPath.map(\.stringValue))
        }
        
        currentIndex += 1
        return string
    }
    
    mutating func decode(_ type: Double.Type) throws -> Double {
        guard
            let (type, offset) = document.typeAndValueOffset(at: currentIndex),
            type == .double,
            let double = document.storage.getDouble(at: offset)
        else {
            throw BSONValueNotFound(type: Double.self, path: codingPath.map(\.stringValue))
        }
        
        currentIndex += 1
        return double
    }
    
    mutating func decode(_ type: Float.Type) throws -> Float {
        guard
            let (type, offset) = document.typeAndValueOffset(at: currentIndex),
            type == .double,
            let double = document.storage.getDouble(at: offset)
        else {
            throw BSONValueNotFound(type: Double.self, path: codingPath.map(\.stringValue))
        }
        
        currentIndex += 1
        return Float(double)
    }
    
    mutating func decode(_ type: Int.Type) throws -> Int {
        #if (arch(i386) || arch(arm)) && BSONInt64Primitive
        let expectedType: TypeIdentifier = .int32
        #else
        let expectedType: TypeIdentifier = .int64
        #endif
        
        guard
            let (foundType, offset) = document.typeAndValueOffset(at: currentIndex),
            foundType == expectedType,
            let int: Int = document.storage.getInteger(at: offset, endianness: .little)
        else {
            throw BSONValueNotFound(type: Int.self, path: codingPath.map(\.stringValue))
        }
        
        currentIndex += 1
        return int
    }
    
    mutating func decode(_ type: Int32.Type) throws -> Int32 {
        guard
            let (type, offset) = document.typeAndValueOffset(at: currentIndex),
            type == .int32,
            let int: Int32 = document.storage.getInteger(at: offset, endianness: .little)
        else {
            throw BSONValueNotFound(type: Int32.self, path: codingPath.map(\.stringValue))
        }
        
        currentIndex += 1
        return int
    }
    
    mutating func decode(_ type: Int64.Type) throws -> Int64 {
        guard
            let (type, offset) = document.typeAndValueOffset(at: currentIndex),
            type == .int64,
            let int: Int64 = document.storage.getInteger(at: offset, endianness: .little)
        else {
            throw BSONValueNotFound(type: Int64.self, path: codingPath.map(\.stringValue))
        }
        
        currentIndex += 1
        return int
    }
    
    mutating func decode(_ type: Int8.Type) throws -> Int8 {
        try decodeFixedWidthInteger()
    }
    
    mutating func decode(_ type: Int16.Type) throws -> Int16 {
        try decodeFixedWidthInteger()
    }
    
    mutating func decode(_ type: UInt.Type) throws -> UInt {
        try decodeFixedWidthInteger()
    }
    
    mutating func decode(_ type: UInt8.Type) throws -> UInt8 {
        try decodeFixedWidthInteger()
    }
    
    mutating func decode(_ type: UInt16.Type) throws -> UInt16 {
        try decodeFixedWidthInteger()
    }
    
    mutating func decode(_ type: UInt32.Type) throws -> UInt32 {
        try decodeFixedWidthInteger()
    }
    
    mutating func decode(_ type: UInt64.Type) throws -> UInt64 {
        try decodeFixedWidthInteger()
    }
    
    @inline(__always)
    mutating func decodeFixedWidthInteger<F: FixedWidthInteger>(_ type: F.Type = F.self) throws -> F {
        guard
            let (type, offset) = document.typeAndValueOffset(at: currentIndex)
        else {
            throw BSONValueNotFound(type: Int64.self, path: codingPath.map(\.stringValue))
        }
        
        switch type {
        case .int32:
            guard
                let int: Int32 = document.storage.getInteger(at: offset, endianness: .little),
                int >= F.min,
                int <= F.max
            else {
                throw BSONValueNotFound(type: F.self, path: codingPath.map(\.stringValue))
            }
            
            currentIndex += 1
            return F(int)
        case .int64:
            guard
                let int: _BSON64BitInteger = document.storage.getInteger(at: offset, endianness: .little),
                int >= F.min,
                int <= F.max
            else {
                throw BSONValueNotFound(type: F.self, path: codingPath.map(\.stringValue))
            }
            
            currentIndex += 1
            return F(int)
        default:
            throw BSONValueNotFound(type: F.self, path: codingPath.map(\.stringValue))
        }
    }
    
    mutating func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
        defer { currentIndex += 1 }
        switch document[currentIndex] {
        case let value as Double: // 0x01
            let decoder = _FastBSONDecoder(value: value)
            return try T.init(from: decoder)
        case let value as String: // 0x0
            let decoder = _FastBSONDecoder(value: value)
            return try T.init(from: decoder)
        case let value as Document: // 0x03 (embedded document) or 0x04 (array)
            let decoder = _FastBSONDecoder(value: value)
            return try T.init(from: decoder)
        case let value as Binary: // 0x05
            if T.self == Data.self {
                return value.data as! T
            }
            
            let decoder = _FastBSONDecoder(value: value)
            return try T.init(from: decoder)
            // 0x06 is deprecated
        case let value as ObjectId: // 0x07
            let decoder = _FastBSONDecoder(value: value)
            return try T.init(from: decoder)
        case let value as Bool: // 0x08
            let decoder = _FastBSONDecoder(value: value)
            return try T.init(from: decoder)
        case let value as Date: // 0x09
            if T.self == Date.self {
                return value as! T
            }
            
            let decoder = _FastBSONDecoder(value: value)
            return try T.init(from: decoder)
        case is Null: // 0x0A
            let decoder = _FastBSONDecoder(value: Null())
            return try T.init(from: decoder)
        case let value as RegularExpression: // 0x0B
            let decoder = _FastBSONDecoder(value: value)
            return try T.init(from: decoder)
            // 0x0C is deprecated (DBPointer)
            // 0x0E is deprecated (Symbol)
        case let value as Int32: // 0x10
            let decoder = _FastBSONDecoder(value: value)
            return try T.init(from: decoder)
        case let value as Timestamp:
            let decoder = _FastBSONDecoder(value: value)
            return try T.init(from: decoder)
        case let value as _BSON64BitInteger: // 0x12
            let decoder = _FastBSONDecoder(value: value)
            return try T.init(from: decoder)
        case let value as Decimal128:
            let decoder = _FastBSONDecoder(value: value)
            return try T.init(from: decoder)
        case is MaxKey: // 0x7F
            let decoder = _FastBSONDecoder(value: MaxKey())
            return try T.init(from: decoder)
        case is MinKey: // 0xFF
            let decoder = _FastBSONDecoder(value: MinKey())
            return try T.init(from: decoder)
        case let value as JavaScriptCode:
            let decoder = _FastBSONDecoder(value: value)
            return try T.init(from: decoder)
        case let value as JavaScriptCodeWithScope:
            let decoder = _FastBSONDecoder(value: value)
            return try T.init(from: decoder)
        default:
            throw BSONValueNotFound(type: Void.self, path: codingPath.map(\.stringValue))
        }
    }
    
    mutating func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
        guard
            let (type, offset) = document.typeAndValueOffset(at: currentIndex),
            type == .document,
            let length = document.storage.getInteger(at: offset, endianness: .little, as: Int32.self),
            let slice = document.storage.getSlice(at: offset, length: numericCast(length))
        else {
            throw BSONValueNotFound(type: Document.self, path: codingPath.map(\.stringValue))
        }
        
        let nestedDocument = Document(buffer: slice, isArray: type == .array)
        currentIndex += 1
        return KeyedDecodingContainer(_FastKeyedContainer<NestedKey>(document: nestedDocument))
    }
    
    mutating func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
        guard
            let (type, offset) = document.typeAndValueOffset(at: currentIndex),
            type == .array,
            let length = document.storage.getInteger(at: offset, endianness: .little, as: Int32.self),
            let slice = document.storage.getSlice(at: offset, length: numericCast(length))
        else {
            throw BSONValueNotFound(type: Document.self, path: codingPath.map(\.stringValue))
        }
        
        let nestedDocument = Document(buffer: slice, isArray: type == .array)
        currentIndex += 1
        return _FastUnkeyedContainer(document: nestedDocument, endIndex: nestedDocument.count)
    }
    
    mutating func superDecoder() throws -> Decoder {
        fatalError()
    }
}
