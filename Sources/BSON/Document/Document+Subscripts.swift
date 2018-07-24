extension Document {
    /// Extracts any `Primitive` fom the value at key `key`
    public subscript(key: String) -> Primitive? {
        get {
            return self.getCached(byKey: key)
        }
        set {
            // calling keys makes the document fully cached
            if !keys.contains(key) {
                self.isArray = false
            }
            
            if let newValue = newValue {
                self.write(newValue, forKey: key)
            } else {
                guard let dimensions = cache.dimensions(forKey: key) else { return }
                
                prepareCacheForMutation()
                
                self.removeBytes(at: dimensions.from, length: dimensions.fullLength)
                cache.handleRemovalOfItem(atPosition: dimensions.from)
            }
        }
    }
}
