extension Document {
    public subscript<D: Decodable>(key: String, as type: D.Type) -> D? {
        return self[key] as? D
    }
    
    public subscript(key: String) -> Primitive? {
        get {
            return self.getCached(byKey: key)
        }
        set {
            if let newValue = newValue {
                withPointer(to: newValue) { pointer, length in
                    if let dimensions = self.dimension(forKey: key) {
                        self.storage.replace(
                            offset: dimensions.from &+ 1 &+ dimensions.keyCString,
                            replacing: dimensions.valueLength,
                            with: pointer,
                            length: length
                        )
                    } else {
                        self.storage.append(from: pointer, length: length)
                    }
                }
            } else {
                guard let dimensions = self.dimension(forKey: key) else { return }
                
                self.storage.remove(from: dimensions.from, length: dimensions.fullLength)
            }
        }
    }
    
    func withPointer<T>(to primitive: Primitive, _ run: (UnsafePointer<UInt8>, Int) throws -> T) rethrows -> T {
        fatalError()
    }
}
