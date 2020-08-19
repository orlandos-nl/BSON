import Foundation

public struct AnyPrimitive: PrimitiveConvertible, Hashable, Encodable, Decodable {
    public static func == (lhs: AnyPrimitive, rhs: AnyPrimitive) -> Bool {
        return lhs.primitive.equals(rhs.primitive)
    }
    
    public func hash(into hasher: inout Hasher) {
        switch primitive {
        case let value as Double:
            value.hash(into: &hasher)
        case let value as String:
            value.hash(into: &hasher)
        case let value as Document:
            value.hash(into: &hasher)
        case let value as Binary:
            value.hash(into: &hasher)
        case let value as ObjectId:
            value.hash(into: &hasher)
        case let value as Bool:
            value.hash(into: &hasher)
        case let value as Date:
            value.hash(into: &hasher)
        case let value as Int32:
            value.hash(into: &hasher)
        case let value as _BSON64BitInteger:
            value.hash(into: &hasher)
        case let value as Timestamp:
            value.hash(into: &hasher)
        case let value as Decimal128:
            value.hash(into: &hasher)
        case is Null:
            ObjectIdentifier(Null.self).hash(into: &hasher)
        case is MaxKey:
            ObjectIdentifier(MaxKey.self).hash(into: &hasher)
        case is MinKey:
            ObjectIdentifier(MinKey.self).hash(into: &hasher)
        case let value as RegularExpression:
            value.hash(into: &hasher)
        case let value as JavaScriptCode:
            value.hash(into: &hasher)
        case let value as JavaScriptCodeWithScope:
            value.hash(into: &hasher)
        case let value as BSONDataType:
            AnyPrimitive(value.primitive).hash(into: &hasher)
        default:
            fatalError("Invalid primitive")
        }
    }
    
    private let primitive: Primitive
    
    public init(_ primitive: Primitive) {
        self.primitive = primitive
    }
    
    public func makePrimitive() -> Primitive? {
        return primitive
    }
    
    public func encode(to encoder: Encoder) throws {
        try primitive.encode(to: encoder)
    }
    
    public init(from decoder: Decoder) throws {
        if let decoder = decoder as? _BSONDecoder {
            self.primitive = decoder.primitive ?? Null()
        } else {
            // TODO: Unsupported decoding method
            throw BSONTypeConversionError(from: Any.self, to: Primitive.self)
        }
    }
}

public struct EitherPrimitive<L: Primitive, R: Primitive>: PrimitiveConvertible, Encodable {
    private enum Value {
        case l(L)
        case r(R)
    }
    private let value: Value
    private var primitive: Primitive {
        switch value {
        case .l(let l):
            return l
        case .r(let r):
            return r
        }
    }
    
    public var lhs: L? {
        switch value {
        case .l(let l): return l
        case .r: return nil
        }
    }
    
    public var rhs: R? {
        switch value {
        case .l: return nil
        case .r(let r): return r
        }
    }
    
    public init(_ value: L) {
        self.value = .l(value)
    }
    
    public init(_ value: R) {
        self.value = .r(value)
    }
    
    public func makePrimitive() -> Primitive? {
        return primitive
    }
    
    public func encode(to encoder: Encoder) throws {
        try primitive.encode(to: encoder)
    }
}
