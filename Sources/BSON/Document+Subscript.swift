extension Document {
    public subscript<D: Decodable>(key: String, as type: D.Type) -> D? {
        return self[key] as? D
    }
    
    public subscript(key: String) -> Primitive? {
        get {
            return self.getCached(byKey: key)
        }
        set {
            return 
        }
    }
}
