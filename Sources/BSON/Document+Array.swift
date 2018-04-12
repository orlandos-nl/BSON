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
}

extension Array where Element == Primitive {
    public init(valuesOf document: Document) {
        self = document.values
    }
}
