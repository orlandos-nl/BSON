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
    
    public subscript(index: Int) -> Primitive {
        get {
            return (self as! Document)[index]
        }
        set {
            var document = self as! Document
            document[index] = newValue
            self = document
        }
    }
}
