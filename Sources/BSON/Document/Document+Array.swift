import Foundation
import NIO

extension Document: ExpressibleByArrayLiteral {
    /// Gets all top level values in this Document
    public var values: [Primitive] {
        var values = [Primitive]()
        values.reserveCapacity(32)

        var index = 4

        while index < storage.readableBytes {
            guard
                let typeNum = storage.getInteger(at: index, as: UInt8.self),
                let type = TypeIdentifier(rawValue: typeNum)
            else {
                return values
            }

            index += 1
            guard skipKey(at: &index) else {
                return values
            }

            guard let value = value(forType: type, at: index) else {
                return values
            }

            _ = skipValue(ofType: type, at: &index)

            values.append(value)
        }

        return values
    }
    
    public subscript(index: Int) -> Primitive {
        get {
            var offset = 4
            for _ in 0..<index {
                guard skipKeyValuePair(at: &offset) else {
                    fatalError("Index \(index) out of range")
                }
            }

            guard
                let typeId = storage.getInteger(at: offset, as: UInt8.self),
                let type = TypeIdentifier(rawValue: typeId)
            else {
                fatalError("Index \(index) out of range")
            }

            guard skipKey(at: &offset), let value = self.value(forType: type, at: offset) else {
                fatalError("Index \(index) out of range")
            }

            return value
        }
        set {
            var offset = 4
            for _ in 0..<index {
                guard skipKeyValuePair(at: &offset) else {
                    fatalError("Index \(index) out of range")
                }
            }
            
            let typeOffset = offset
            
            guard
                let typeByte = storage.getInteger(at: typeOffset, as: UInt8.self),
                let type = TypeIdentifier(rawValue: typeByte)
            else {
                fatalError("Index \(index) out of range")
            }
            
            offset += 1
            
            guard skipKey(at: &offset) else {
                fatalError("Index \(index) out of range")
            }
            
            let valueOffset = offset
            
            guard let oldValueLength = valueLength(forType: type, at: offset) else {
                fatalError("Index \(index) out of range")
            }
            
            let valueEnd = valueOffset + oldValueLength
            
            func reserveRoom(_ type: TypeIdentifier, _ newValueLength: Int) {
                storage.setInteger(type.rawValue, at: typeOffset)
                
                let newValueEnd = valueOffset + newValueLength
                let diff = oldValueLength - newValueLength
                let movedLength = numericCast(self.usedCapacity) - valueEnd
                
                if oldValueLength < newValueLength {
                    storage.writeBytes(ContiguousArray<UInt8>(repeating: 0x00, count: -diff))
                }
                
                self.usedCapacity -= Int32(diff)
                
                moveBytes(
                    from: valueEnd,
                    to: newValueEnd,
                    length: movedLength
                )
                
                if diff > 0 {
                    storage.moveWriterIndex(to: storage.writerIndex - diff)
                }
            }
            
            switch newValue {
            case let double as Double: // 0x01
                reserveRoom(.double, 8)
                storage.setInteger(double.bitPattern, at: valueOffset, endianness: .little)
            case let string as String: // 0x0
                let stringUtf8Length = string.utf8.count
                reserveRoom(.string, 4 + stringUtf8Length + 1)
                storage.setInteger(Int32(stringUtf8Length + 1), at: valueOffset, endianness: .little)
                storage.setString(string, at: valueOffset + 4)
                storage.setInteger(0, at: valueOffset + 4 + stringUtf8Length, endianness: .little, as: UInt8.self)
            case let document as Document: // 0x03 (embedded document) or 0x04 (array)
                reserveRoom(document.isArray ? .array : .document, document.storage.writerIndex)
                storage.setBuffer(document.storage, at: valueOffset)
            case let binary as Binary: // 0x05
                reserveRoom(.binary, 4 + 1 + binary.count)
                storage.setInteger(Int32(binary.count), at: valueOffset, endianness: .little)
                storage.setInteger(binary.subType.identifier, at: valueOffset + 4, endianness: .little)
                storage.setBuffer(binary.storage, at: valueOffset + 4 + 1)
            // 0x06 is deprecated
            case let objectId as ObjectId: // 0x07
                reserveRoom(.objectId, 12)
                storage.setInteger(objectId._timestamp, at: valueOffset, endianness: .big)
                storage.setInteger(objectId._random, at: valueOffset + 4, endianness: .big)
            case let bool as Bool: // 0x08
                reserveRoom(.boolean, 1)
                let bool: UInt8 = bool ? 0x01 : 0x00
                storage.setInteger(bool, at: valueOffset, endianness: .little)
            case let date as Date: // 0x09
                reserveRoom(.datetime, 8)
                let milliseconds = Int(date.timeIntervalSince1970 * 1000)
                storage.setInteger(milliseconds, at: valueOffset, endianness: .little)
            case is Null: // 0x0A
                reserveRoom(.null, 0)
            case let regex as RegularExpression: // 0x0B
                let patternSize = regex.pattern.utf8.count
                let optionsSize = regex.options.utf8.count
                
                reserveRoom(.regex, patternSize + 1 + optionsSize + 1)
                Swift.assert(!regex.pattern.contains("\0"))
                Swift.assert(!regex.options.contains("\0"))

                // string counts + null terminators
                storage.setString(regex.pattern, at: valueOffset)
                storage.setInteger(0x00, at: valueOffset + patternSize, endianness: .little, as: UInt8.self)

                storage.setString(regex.options, at: valueOffset + patternSize + 1)
                storage.setInteger(0x00, at: valueOffset + patternSize + 1 + optionsSize, endianness: .little, as: UInt8.self)
                // 0x0C is deprecated (DBPointer)
            // 0x0E is deprecated (Symbol)
            case let int as Int32: // 0x10
                reserveRoom(.int32, 4)
                storage.setInteger(int, at: valueOffset, endianness: .little)
            case let stamp as Timestamp:
                reserveRoom(.timestamp, 8)
                storage.setInteger(stamp.increment, at: valueOffset, endianness: .little)
                storage.setInteger(stamp.timestamp, at: valueOffset + 4, endianness: .little)
            case let int as _BSON64BitInteger: // 0x12
                reserveRoom(.int64, 8)
                storage.setInteger(int, at: valueOffset, endianness: .little)
            case let decimal128 as Decimal128:
                reserveRoom(.decimal128, 16)
                storage.setBytes(decimal128.storage, at: valueOffset)
            case is MaxKey: // 0x7F
                reserveRoom(.maxKey, 0)
            case is MinKey: // 0xFF
                reserveRoom(.minKey, 0)
            case let javascript as JavaScriptCode:
                let utf8Size = javascript.code.utf8.count
                let codeLengthWithNull = utf8Size + 1
                reserveRoom(.javascript, 4 + codeLengthWithNull)
                storage.setInteger(Int32(codeLengthWithNull), at: valueOffset, endianness: .little)
                storage.setString(javascript.code, at: valueOffset + 4)
                storage.setInteger(0, at: valueOffset + 4 + utf8Size, endianness: .little, as: UInt8.self)
            case let javascript as JavaScriptCodeWithScope:
                let scopeBuffer = javascript.scope.makeByteBuffer()
                let utf8Size = javascript.code.utf8.count
                let codeLength = utf8Size + 1 // code, null terminator
                let codeLengthWithHeader = 4 + codeLength
                let primitiveLength = 4 + codeLengthWithHeader + scopeBuffer.readableBytes // int32(code_w_s size), code, scope doc
                reserveRoom(.javascriptWithScope, primitiveLength)
                
                var offset = valueOffset
                
                storage.setInteger(Int32(primitiveLength), at: offset, endianness: .little) // header
                offset += 4
                
                storage.setInteger(Int32(codeLength), at: offset, endianness: .little) // string (code)
                offset += 4
                
                storage.setString(javascript.code, at: offset)
                offset += utf8Size
                
                storage.setInteger(0, at: offset, endianness: .little, as: UInt8.self)
                offset += 1
                
                storage.setBuffer(scopeBuffer, at: offset)
            case let bsonData as BSONDataType:
                if let value = bsonData.makePrimitive() {
                    self[index] = value
                }
            default:
                assertionFailure("Currently unsupported type \(primitive)")
                return
            }
        }
    }

    public mutating func remove(at index: Int) {
        var offset = 4

        for _ in 0..<index {
            guard skipKeyValuePair(at: &offset) else {
                fatalError("Index \(index) out of range")
            }
        }

        let base = offset
        guard skipKeyValuePair(at: &offset) else {
            fatalError("Index \(index) out of range")
        }

        let length = offset - base

        self.removeBytes(at: base, length: length)
    }

    /// Appends a `Value` to this `Document` where this `Document` acts like an `Array`
    ///
    /// TODO: Analyze what should happen with `Dictionary`-like documents and this function
    ///
    /// - parameter value: The `Value` to append
    public mutating func append(_ value: Primitive) {
        let key = String(self.count)
        
        appendValue(value, forKey: key)
    }
    
    /// TODO: Analyze what should happen with `Dictionary`-like documents and this function
    public mutating func insert(contentsOf document: Document, at index: Int) {
        Swift.assert(index <= count, "Value inserted at \(index) exceeds current count of \(count)")
        
        var document = Document(isArray: true)
        
        for i in 0..<self.count {
            if i == index {
                for value in document.values {
                    document.append(value)
                }
            }
            
            document.append(self[i])
        }
        
        self = document
    }
    
    /// TODO: Analyze what should happen with `Dictionary`-like documents and this function
    public mutating func insert(_ value: Primitive, at index: Int) {
        Swift.assert(index <= count, "Value inserted at \(index) exceeds current count of \(count)")
        
        var document = Document(isArray: true)
        
        for i in 0..<self.count {
            if i == index {
                document.append(value)
            }
            
            document.append(self[i])
        }
        
        self = document
    }
    
    public init(arrayLiteral elements: PrimitiveConvertible...) {
        self.init(array: elements.compactMap { $0.makePrimitive() } )
    }
    
    /// Converts an array of Primitives to a BSON ArrayDocument
    public init(array: [Primitive]) {
        self.init(isArray: true)
        
        for element in array {
            self.append(element)
        }
    }
}

extension Array where Element == Primitive {
    public init(valuesOf document: Document) {
        self = document.values
    }
}
