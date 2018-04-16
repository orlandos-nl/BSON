extension Document {
    /// Gets all top level values in this Document
    public var values: [Primitive] {
        _ = self.scanValue(startingAt: self.lastScannedPosition, mode: .all)
        
        return self.cache.storage.flatMap { (_, dimension) in
            return self.readPrimitive(atDimensions: dimension)
        }
    }
    
    subscript(index: Int) -> Primitive? {
        repeat {
            if self.cache.storage.count > index {
                return self[valueFor: self[dimensionsAt: index]]
            }
            
            _ = self.scanValue(startingAt: self.lastScannedPosition, mode: .single)
        } while !self.fullyCached
        
        return nil
    }
    
    /// Appends a `Value` to this `Document` where this `Document` acts like an `Array`
    ///
    /// TODO: Analyze what should happen with `Dictionary`-like documents and this function
    ///
    /// - parameter value: The `Value` to append
    public mutating func append(_ value: Primitive) {
        let key = String(self.count)
        
        self.write(value, forKey: key)
    }
}

extension Array where Element == Primitive {
    public init(valuesOf document: Document) {
        self = document.values
    }
}
