import Foundation
import NIO

extension Document: ExpressibleByDictionaryLiteral {
    /// Gets all top level keys in this Document
    public var keys: [String] {
        var keys = [String]()
        keys.reserveCapacity(32)

        var index = 4

        while index < storage.readableBytes {
            guard
                let typeNum = storage.getInteger(at: index, as: UInt8.self),
                let type = TypeIdentifier(rawValue: typeNum)
            else {
                // If typeNum == 0, end of document
                return keys
            }
            
            index += 1

            guard
                let length = storage.firstRelativeIndexOf(byte: 0x00, startingAt: index),
                let key = storage.getString(at: index, length: length)
            else {
                return keys
            }

            keys.append(key)
            index += length + 1 // including null terminator
            guard skipValue(ofType: type, at: &index) else {
                return keys
            }
        }

        return keys
    }
    
    /// Tries to extract a value of type `P` from the value at key `key`
    internal subscript<P: Primitive>(key: String, as type: P.Type) -> P? {
        return self[key] as? P
    }
    
    /// Creates a new Document from a Dictionary literal
    public init(dictionaryLiteral elements: (String, PrimitiveConvertible)...) {
        self.init(elements: elements.lazy.compactMap { key, value in
            guard let primitive = value.makePrimitive() else {
                return nil // continue
            }
            
            return (key, primitive)
        })
    }

    mutating func appendValue(_ value: Primitive, forKey key: String) {
        defer {
            usedCapacity = Int32(self.storage.readableBytes)
        }

        func writeKey(_ type: TypeIdentifier) {
            storage.moveWriterIndex(to: storage.writerIndex - 1)
            storage.write(integer: type.rawValue)
            storage.write(string: key)
            storage.write(integer: 0x00 as UInt8)
        }

        switch value {
        case let double as Double: // 0x01
            writeKey(.double)
            storage.write(integer: double.bitPattern, endianness: .little)
        case let string as String: // 0x02
            writeKey(.string)
            let lengthIndex = storage.writerIndex
            storage.write(integer: Int32(0), endianness: .little)
            storage.write(string: string)
            storage.write(integer: 0, endianness: .little, as: UInt8.self)
            let length = storage.writerIndex - 4 - lengthIndex
            storage.set(integer: Int32(length), at: lengthIndex, endianness: .little)
        case var document as Document: // 0x03 (embedded document) or 0x04 (array)
            writeKey(document.isArray ? .array : .document)
            storage.write(buffer: &document.storage)
        case let binary as Binary: // 0x05
            writeKey(.binary)
            storage.write(integer: Int32(binary.count), endianness: .little)
            storage.write(integer: binary.subType.identifier, endianness: .little)
            var buffer = binary.storage
            storage.write(buffer: &buffer)
        // 0x06 is deprecated
        case let objectId as ObjectId: // 0x07
            writeKey(.objectId)
            storage.write(integer: objectId.byte0)
            storage.write(integer: objectId.byte1)
            storage.write(integer: objectId.byte2)
            storage.write(integer: objectId.byte3)
            storage.write(integer: objectId.byte4)
            storage.write(integer: objectId.byte5)
            storage.write(integer: objectId.byte6)
            storage.write(integer: objectId.byte7)
            storage.write(integer: objectId.byte8)
            storage.write(integer: objectId.byte9)
            storage.write(integer: objectId.byte10)
            storage.write(integer: objectId.byte11)
        case let bool as Bool: // 0x08
            writeKey(.boolean)
            let bool: UInt8 = bool ? 0x01 : 0x00
            storage.write(integer: bool, endianness: .little)
        case let date as Date: // 0x09
            writeKey(.datetime)
            let milliseconds = Int(date.timeIntervalSince1970 * 1000)
            storage.write(integer: milliseconds, endianness: .little)
        case is Null: // 0x0A
            writeKey(.null)
        case let regex as RegularExpression: // 0x0B
            writeKey(.regex)
            Swift.assert(!regex.pattern.contains("\0"))
            Swift.assert(!regex.options.contains("\0"))

            // string counts + null terminators
            storage.write(string: regex.pattern)
            storage.write(integer: 0x00, endianness: .little, as: UInt8.self)

            storage.write(string: regex.options)
            storage.write(integer: 0x00, endianness: .little, as: UInt8.self)
            // 0x0C is deprecated (DBPointer)
        // 0x0E is deprecated (Symbol)
        case let int as Int32: // 0x10
            writeKey(.int32)
            storage.write(integer: int, endianness: .little)
        case let stamp as Timestamp:
            writeKey(.timestamp)
            storage.write(integer: stamp.increment, endianness: .little)
            storage.write(integer: stamp.timestamp, endianness: .little)
        case let int as Int: // 0x12
            writeKey(.int64)
            storage.write(integer: int, endianness: .little)
        case let decimal128 as Decimal128:
            writeKey(.decimal128)
            storage.write(bytes: decimal128.storage)
        case is MaxKey: // 0x7F
            writeKey(.maxKey)
        case is MinKey: // 0xFF
            writeKey(.minKey)
        case let javascript as JavaScriptCode:
            writeKey(.javascript)
            let codeLengthWithNull = javascript.code.utf8.count + 1
            storage.write(integer: Int32(codeLengthWithNull), endianness: .little)
            storage.write(string: javascript.code)
            storage.write(integer: 0, endianness: .little, as: UInt8.self)
        case let javascript as JavaScriptCodeWithScope:
            writeKey(.javascriptWithScope)
            var codeBuffer = javascript.scope.makeByteBuffer()
            let codeLength = javascript.code.utf8.count + 1 // code, null terminator
            let codeLengthWithHeader = 4 + codeLength
            let primitiveLength = 4 + codeLengthWithHeader + codeBuffer.writerIndex // int32(code_w_s size), code, scope doc

            storage.write(integer: Int32(primitiveLength), endianness: .little) // header
            storage.write(integer: codeLength) // string (code)
            storage.write(string: javascript.code)
            storage.write(buffer: &codeBuffer)
        case let bsonData as BSONDataType:
            self.appendValue(bsonData.primitive, forKey: key)
            return
        default:
//            guard let data = primitive as? BSONDataType else {
            assertionFailure("Currently unsupported type \(primitive)")
            return
        }

        storage.write(integer: 0, endianness: .little, as: UInt8.self)
    }
    
    /// Creates a new Document with the given elements
    // TODO: @_specialize ?
    public init<S: Sequence>(elements: S, isArray: Bool = false) where S.Element == (String, PrimitiveConvertible) {
        self.init(isArray: isArray)
        for (key, value) in elements {
            guard let value = value.makePrimitive() else {
                continue
            }
            
            self.appendValue(value, forKey: key)
        }
    }
}

extension Dictionary where Key == String, Value == Primitive {
    public init(document: Document) {
        self.init()
        
        for (key, value) in document {
            self[key] = value
        }
    }
}
