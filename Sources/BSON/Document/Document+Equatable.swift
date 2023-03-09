import Foundation

extension Document: Equatable {
    public static func == (lhs: Document, rhs: Document) -> Bool {
        if lhs.isArray != rhs.isArray {
            return false
        }
        
        var lhsBuffer = lhs.storage
        var rhsBuffer = rhs.storage
        
        guard lhsBuffer.readableBytes > 4, rhsBuffer.readableBytes > 4 else {
            return false
        }
        
        lhsBuffer.moveReaderIndex(forwardBy: 4)
        rhsBuffer.moveReaderIndex(forwardBy: 4)
        
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
            let rhsType = TypeIdentifier(rawValue: rhsTypeId)
        else {
            return false
        }
        
        // Both types must match
        guard lhsType == rhsType else {
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
        
        if lhs.isArray {
            // For arrays, only care about indices. Not keys
            // Skip until after the null terminator
            lhsBuffer.moveReaderIndex(forwardBy: lhsLength + 1)
            rhsBuffer.moveReaderIndex(forwardBy: rhsLength + 1)
        } else {
            let lhsKey = lhsBuffer.readString(length: lhsLength)
            let rhsKey = rhsBuffer.readString(length: rhsLength)
            
            guard lhsKey == rhsKey else {
                return false
            }
            
            // Skip null terminator
            lhsBuffer.moveReaderIndex(forwardBy: 1)
            rhsBuffer.moveReaderIndex(forwardBy: 1)
        }
        
        guard
            let lhsLength = lhs.valueLength(forType: lhsType, at: lhsBuffer.readerIndex),
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
        } else {
            guard lhsSlice == rhsSlice else {
                return false
            }
        }
        
        return true
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
