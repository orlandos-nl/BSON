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
                let length = storage.firstRelativeIndexOf(startingAt: index),
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
    
    public func containsKey(_ key: String) -> Bool {
        var index = 4
        let keyLength = key.utf8.count

        while index < storage.readableBytes {
            guard
                let typeNum = storage.getInteger(at: index, as: UInt8.self),
                let type = TypeIdentifier(rawValue: typeNum)
            else {
                // If typeNum == 0, end of document
                return false
            }
            
            index += 1

            guard
                let length = storage.firstRelativeIndexOf(startingAt: index)
            else {
                return false
            }

            if length == keyLength {
                let isMatchingKey = storage.withUnsafeReadableBytes { pointer in
                    memcmp(pointer.baseAddress! + index, key, length) == 0
                }
                
                if isMatchingKey {
                    return true
                }
            }
            
            index += length + 1 // including null terminator
            guard skipValue(ofType: type, at: &index) else {
                return false
            }
        }

        return false
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
    
    public mutating func append(contentsOf document: Document) {
        for (key, value) in document {
            self.appendValue(value, forKey: key)
        }
    }
    
    public mutating func insert(_ value: Primitive, forKey key: String, at index: Int) {
        Swift.assert(index <= count, "Value inserted at \(index) exceeds current count of \(count)")
        
        var document = Document()
        var pairs = self.pairs
        var i = 0
        
        while let pair = pairs.next() {
            if i == index {
                document.appendValue(value, forKey: key)
            }
            
            document.appendValue(pair.value, forKey: pair.key)
            i += 1
        }
        
        if index == i {
            document.appendValue(value, forKey: key)
        }
        
        self = document
    }

    public mutating func removeValue(forKey key: String) -> Primitive? {
        if let value = self[key] {
            self[key] = nil
            return value
        }

        return nil
    }

    public mutating func appendValue(_ value: Primitive, forKey key: String) {
        defer {
            usedCapacity = Int32(self.storage.readableBytes)
        }

        func writeKey(_ type: TypeIdentifier) {
            storage.moveWriterIndex(to: storage.writerIndex - 1)
            storage.writeInteger(type.rawValue)
            storage.writeString(key)
            storage.writeInteger(0x00 as UInt8)
        }

        switch value {
        case let double as Double: // 0x01
            writeKey(.double)
            storage.writeInteger(double.bitPattern, endianness: .little)
        case let string as String: // 0x02
            writeKey(.string)
            let lengthIndex = storage.writerIndex
            storage.writeInteger(Int32(0), endianness: .little)
            storage.writeString(string)
            storage.writeInteger(0, endianness: .little, as: UInt8.self)
            let length = storage.writerIndex - 4 - lengthIndex
            storage.setInteger(Int32(length), at: lengthIndex, endianness: .little)
        case var document as Document: // 0x03 (embedded document) or 0x04 (array)
            writeKey(document.isArray ? .array : .document)
            storage.writeBuffer(&document.storage)
        case let binary as Binary: // 0x05
            writeKey(.binary)
            storage.writeInteger(Int32(binary.count), endianness: .little)
            storage.writeInteger(binary.subType.identifier, endianness: .little)
            var buffer = binary.storage
            storage.writeBuffer(&buffer)
        // 0x06 is deprecated
        case let objectId as ObjectId: // 0x07
            writeKey(.objectId)
            storage.writeInteger(objectId._timestamp, endianness: .big)
            storage.writeInteger(objectId._random, endianness: .big)
        case let bool as Bool: // 0x08
            writeKey(.boolean)
            let bool: UInt8 = bool ? 0x01 : 0x00
            storage.writeInteger(bool, endianness: .little)
        case let date as Date: // 0x09
            writeKey(.datetime)
            let milliseconds = Int(date.timeIntervalSince1970 * 1000)
            storage.writeInteger(milliseconds, endianness: .little)
        case is Null: // 0x0A
            writeKey(.null)
        case let regex as RegularExpression: // 0x0B
            writeKey(.regex)
            Swift.assert(!regex.pattern.contains("\0"))
            Swift.assert(!regex.options.contains("\0"))

            // string counts + null terminators
            storage.writeString(regex.pattern)
            storage.writeInteger(0x00, endianness: .little, as: UInt8.self)

            storage.writeString(regex.options)
            storage.writeInteger(0x00, endianness: .little, as: UInt8.self)
            // 0x0C is deprecated (DBPointer)
        // 0x0E is deprecated (Symbol)
        case let int as Int32: // 0x10
            writeKey(.int32)
            storage.writeInteger(int, endianness: .little)
        case let stamp as Timestamp:
            writeKey(.timestamp)
            storage.writeInteger(stamp.increment, endianness: .little)
            storage.writeInteger(stamp.timestamp, endianness: .little)
        case let int as _BSON64BitInteger: // 0x12
            writeKey(.int64)
            storage.writeInteger(int, endianness: .little)
        case let decimal128 as Decimal128:
            writeKey(.decimal128)
            storage.writeBytes(decimal128.storage)
        case is MaxKey: // 0x7F
            writeKey(.maxKey)
        case is MinKey: // 0xFF
            writeKey(.minKey)
        case let javascript as JavaScriptCode:
            writeKey(.javascript)
            let codeLengthWithNull = javascript.code.utf8.count + 1
            storage.writeInteger(Int32(codeLengthWithNull), endianness: .little)
            storage.writeString(javascript.code)
            storage.writeInteger(0, endianness: .little, as: UInt8.self)
        case let javascript as JavaScriptCodeWithScope:
            writeKey(.javascriptWithScope)
            var scopeBuffer = javascript.scope.makeByteBuffer()
            let codeLength = javascript.code.utf8.count + 1 // code, null terminator
            let codeLengthWithHeader = 4 + codeLength
            let primitiveLength = 4 + codeLengthWithHeader + scopeBuffer.readableBytes // int32(code_w_s size), code, scope doc

            storage.writeInteger(Int32(primitiveLength), endianness: .little) // header
            storage.writeInteger(Int32(codeLength), endianness: .little) // string (code)
            storage.writeString(javascript.code)
            storage.writeInteger(0, endianness: .little, as: UInt8.self)
            storage.writeBuffer(&scopeBuffer)
        case let bsonData as BSONDataType:
            self.appendValue(bsonData.primitive, forKey: key)
            return
        default:
//            guard let data = primitive as? BSONDataType else {
            assertionFailure("Currently unsupported type \(primitive)")
            return
        }

        storage.writeInteger(0, endianness: .little, as: UInt8.self)
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
