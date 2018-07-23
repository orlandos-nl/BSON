/// Implemented by types that are convertible to a primitive
public protocol PrimitiveConvertible {
    func makePrimitive() -> Primitive?
}

extension Primitive {
    public func makePrimitive() -> Primitive? {
        return self
    }
}

// - MARK: Sequences

fileprivate extension Sequence where Element: PrimitiveConvertible {
    func makeDocument() -> Document {
        return Document(elements: self.enumerated().map { ("\($0)", $1 as PrimitiveConvertible) }, isArray: true)
    }
}

extension Array: PrimitiveConvertible where Element: PrimitiveConvertible {
    public func makePrimitive() -> Primitive? {
        return self.makeDocument()
    }
}

// TODO: Discuss: Should set be PrimitiveConvertible? Maybe it is, because it is also a sequence.
extension Set: PrimitiveConvertible where Element: PrimitiveConvertible {
    public func makePrimitive() -> Primitive? {
        return self.makeDocument()
    }
}

extension Dictionary: PrimitiveConvertible where Key == String, Value: PrimitiveConvertible {
    public func makePrimitive() -> Primitive? {
        return Document(elements: self.compactMap { element in
            guard let primitive = element.value.makePrimitive() else {
                return nil // continue
            }
            
            return (element.key, primitive)
        })
    }
}

// - MARK: Optional

fileprivate enum BSONInternalUnknownTypeForPrimitiveConvertibleConversion: Primitive {
    case invalid // if we don't include a case, Swift generates a warning "Will never be executed"
    
    init(from decoder: Decoder) throws {
        self = .invalid
    }
    
    func encode(to encoder: Encoder) throws {
        preconditionFailure()
    }
}

extension Optional: PrimitiveConvertible where Wrapped: PrimitiveConvertible {
    public func makePrimitive() -> Primitive? {
        switch self {
        case .none: return nil
        case .some(let wrapped): return wrapped.makePrimitive()
        }
    }
}
