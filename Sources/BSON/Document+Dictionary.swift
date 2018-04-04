extension Document {
    public var keys: [String] {
        self.completeTopLevelCache()
        let pointer = self.storage.readBuffer.baseAddress!
        
        return self.cache.storage.map { (_, dimension) in
            // + 1 for the type identifier
            let pointer = pointer.advanced(by: dimension.from &+ 1)
            return String(cString: pointer)
        }
    }
}
