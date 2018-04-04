extension Document {
    public var keys: [String] {
        _ = self.scanValue(startingAt: self.lastScannedPosition, mode: .all)
        let pointer = self.storage.readBuffer.baseAddress!
        
        return self.cache.storage.map { (_, dimension) in
            // + 1 for the type identifier
            let pointer = pointer.advanced(by: dimension.from &+ 1)
            return String(cString: pointer)
        }
    }
    
    public subscript<P: Primitive>(key: String, as type: P.Type) -> P? {
        return self[key] as? P
    }
    
    public subscript(key: String) -> Primitive? {
        get {
            return self.getCached(byKey: key)
        }
        set {
            if let newValue = newValue {
                self.write(newValue, forKey: key)
            } else {
                guard let dimensions = self.dimension(forKey: key) else { return }
                
                self.storage.remove(from: dimensions.from, length: dimensions.fullLength)
            }
        }
    }
}
