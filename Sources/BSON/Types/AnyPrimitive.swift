import Foundation

public struct AnyPrimitive: PrimitiveConvertible, Encodable {
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
