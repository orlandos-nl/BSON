extension Optional: Primitive where Wrapped: Primitive {}

extension Optional where Wrapped == Primitive {
    
    public subscript(key: String) -> Primitive? {
        get {
            return (self as? Document)?[key]
        }
        set {
            var document = (self as? Document) ?? [:]
            document[key] = newValue
            self = document
        }
    }
}

