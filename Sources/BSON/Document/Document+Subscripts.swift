extension Document {
    /// Extracts any `Primitive` fom the value at key `key`
    public subscript(key: String) -> Primitive? {
        get {
            return self.getCached(byKey: key)
        }
        set {
            if !keys.contains(key) {
                self.isArray = false
            }
            
            if let newValue = newValue {
                self.write(newValue, forKey: key)
            } else {
                guard let dimensions = self.dimension(forKey: key) else { return }
                
                self.storage.remove(from: dimensions.from, length: dimensions.fullLength)
                
                for i in 0..<self.cache.storage.count {
                    if self.cache.storage[i].0 == key {
                        self.cache.storage.remove(at: i)
                        return
                    }
                }
            }
        }
    }
}
