import Foundation

extension Document: Equatable {
    private func equateAsArray(with rhs: Document) -> Bool {
        var lhsBuffer = self.storage
        var rhsBuffer = rhs.storage
        
        guard lhsBuffer.readableBytes > 4, rhsBuffer.readableBytes > 4 else {
            return false
        }
        
        lhsBuffer.moveReaderIndex(forwardBy: 4)
        rhsBuffer.moveReaderIndex(forwardBy: 4)
        
        while let byte = lhsBuffer.getByte(at: lhsBuffer.readerIndex), byte != 0x00 {
            // Check the next LHS value type
            guard
                let lhsTypeId: UInt8 = lhsBuffer.readInteger(),
                let lhsType = TypeIdentifier(rawValue: lhsTypeId)
            else {
                // Both counts end here
                if
                    let rhsTypeId: UInt8 = rhsBuffer.readInteger()
                {
                    return rhsTypeId == 0
                } else {
                    return true
                }
            }
            
            // Check the next RHS value type
            guard
                let rhsTypeId: UInt8 = rhsBuffer.readInteger(),
                let rhsType = TypeIdentifier(rawValue: rhsTypeId),
                lhsType == rhsType
            else {
                return false
            }
            
            // Since they're both the same, this is now our type
            let type = lhsType
            
            guard
                let lhsLength = lhsBuffer.firstRelativeIndexOf(startingAt: 0),
                lhsLength + 1 < lhsBuffer.readableBytes,
                let rhsLength = rhsBuffer.firstRelativeIndexOf(startingAt: 0),
                rhsLength + 1 < rhsBuffer.readableBytes
            else {
                // Corrupt buffer
                return false
            }
            
            // For arrays, only care about indices. Not keys
            // Skip until after the null terminator
            lhsBuffer.moveReaderIndex(forwardBy: lhsLength + 1)
            rhsBuffer.moveReaderIndex(forwardBy: rhsLength + 1)
            
            let lhsValueIndex = lhsBuffer.readerIndex
            let rhsValueIndex = rhsBuffer.readerIndex
            
            guard
                let lhsLength = self.valueLength(forType: lhsType, at: lhsBuffer.readerIndex),
                let rhsLength = rhs.valueLength(forType: rhsType, at: rhsBuffer.readerIndex),
                let lhsSlice = lhsBuffer.readSlice(length: Int(lhsLength)),
                let rhsSlice = rhsBuffer.readSlice(length: Int(rhsLength))
            else {
                return false
            }
            
            if type == .array || type == .document {
                let lhsSubDocument = Document(buffer: lhsSlice, isArray: type == .array)
                let rhsSubDocument = Document(buffer: rhsSlice, isArray: type == .array)
                
                guard lhsSubDocument == rhsSubDocument else {
                    return false
                }
            } else if type == .javascriptWithScope {
                // Shortcut for a less commonly used type
                guard
                    let lhsValue = self.value(forType: .javascriptWithScope, at: lhsValueIndex) as? JavaScriptCodeWithScope,
                    let rhsValue = rhs.value(forType: .javascriptWithScope, at: rhsValueIndex) as? JavaScriptCodeWithScope,
                    lhsValue == rhsValue
                else {
                    return false
                }
            } else {
                guard lhsLength == rhsLength, lhsSlice == rhsSlice else {
                    return false
                }
            }
        }
        
        if let byte = rhsBuffer.getByte(at: rhsBuffer.readerIndex), byte != 0x00 {
            // RHS had more data
            return false
        }
        
        return true
    }
    
    private func equateAsDictionary(with rhs: Document) -> Bool {
        var lhsBuffer = self.storage
        let rhsBuffer = rhs.storage
        
        guard lhsBuffer.readableBytes > 4, rhsBuffer.readableBytes > 4 else {
            return false
        }
        
        lhsBuffer.moveReaderIndex(forwardBy: 4)
        
        var count = 0
        let rhsCount = rhs.count
        
        while let byte = lhsBuffer.getByte(at: lhsBuffer.readerIndex), byte != 0x00 {
            count += 1
            
            // Early exit, rhs has less fields than lhs
            if count > rhsCount {
                return false
            }
            
            // Read the next LHS value type
            guard
                let lhsTypeId: UInt8 = lhsBuffer.readInteger(),
                let lhsType = TypeIdentifier(rawValue: lhsTypeId)
            else {
                // Unknown type identifier
                return false
            }
            
            guard
                let lhsKey = lhsBuffer.readNullTerminatedString(),
                let (rhsType, rhsOffset) = rhs.typeAndValueOffset(forKey: lhsKey)
            else {
                // Corrupt buffer
                return false
            }
            
            // Both types must match
            guard lhsType == rhsType else {
                return false
            }
            
            // Since they're both the same, this is now our type
            let type = lhsType
            
            guard
                let lhsLength = self.valueLength(forType: lhsType, at: lhsBuffer.readerIndex),
                let rhsLength = rhs.valueLength(forType: rhsType, at: rhsOffset),
                let lhsSlice = lhsBuffer.readSlice(length: Int(lhsLength)),
                let rhsSlice = rhsBuffer.getSlice(at: rhsOffset, length: Int(rhsLength))
            else {
                return false
            }
            
            if type == .array || type == .document {
                let lhsSubDocument = Document(buffer: lhsSlice, isArray: type == .array)
                let rhsSubDocument = Document(buffer: rhsSlice, isArray: type == .array)
                
                guard lhsSubDocument == rhsSubDocument else {
                    return false
                }
            } else {
                guard lhsSlice == rhsSlice else {
                    return false
                }
            }
        }
        
        // Ensure lhs and rhs had all their fields scanned
        return count == rhsCount
    }
    
    public static func == (lhs: Document, rhs: Document) -> Bool {
        if lhs.isArray != rhs.isArray {
            return false
        }
        
        if lhs.isArray {
            return lhs.equateAsArray(with: rhs)
        } else {
            return lhs.equateAsDictionary(with: rhs)
        }
    }
}

extension Primitive {
    public func equals(_ primitive: Primitive) -> Bool {
        switch (self, primitive) {
        case (let lhs as Double, let rhs as Double):
            return lhs == rhs
        case (let lhs as String, let rhs as String):
            return lhs == rhs
        case (let lhs as Document, let rhs as Document):
            return lhs == rhs
        case (let lhs as Binary, let rhs as Binary):
            return lhs == rhs
        case (let lhs as ObjectId, let rhs as ObjectId):
            return lhs == rhs
        case (let lhs as Bool, let rhs as Bool):
            return lhs == rhs
        case (let lhs as Date, let rhs as Date):
            return lhs == rhs
        case (is Null, is Null):
            return true
        case (let lhs as RegularExpression, let rhs as RegularExpression):
            return lhs == rhs
        case (let lhs as Int32, let rhs as Int32):
            return lhs == rhs
        case (let lhs as Timestamp, let rhs as Timestamp):
            return lhs == rhs
        case (let lhs as _BSON64BitInteger, let rhs as _BSON64BitInteger):
            return lhs == rhs
        case (let lhs as Decimal128, let rhs as Decimal128):
            return lhs == rhs
        case (is MaxKey, is MaxKey):
            return true
        case (is MinKey, is MinKey):
            return true
        case (let lhs as JavaScriptCode, let rhs as JavaScriptCode):
            return lhs == rhs
        case (let lhs as JavaScriptCodeWithScope, let rhs as JavaScriptCodeWithScope):
            return lhs == rhs
        default:
            return false
        }
    }
}


extension Document: Hashable {
    public func hash(into hasher: inout Hasher) {
        self.makeByteBuffer().withUnsafeReadableBytes { buffer in
            hasher.combine(bytes: buffer)
        }
    }
}
