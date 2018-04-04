extension Document {
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
