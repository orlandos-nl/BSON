import Foundation

extension Document: Equatable {
    public static func == (lhs: Document, rhs: Document) -> Bool {
        if lhs.isArray != rhs.isArray {
            return false
        }
        
        if lhs.count != rhs.count {
            return false
        }
        
        if lhs.isArray {
            for i in 0..<lhs.count {
                let lhsValue = lhs[i]
                let rhsValue = rhs[i]
                
                guard
                    lhsValue.equals(rhsValue)
                else {
                    return false
                }
            }
        } else {
            for key in lhs.keys {
                guard
                    let lhsValue = lhs[key],
                    let rhsValue = rhs[key],
                    lhsValue.equals(rhsValue)
                else {
                    return false
                }
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
