extension Document: Sequence {
    public var count: Int {
        self.completeTopLevelCache()
        
        return self.cache.storage.count
    }
    
    public func makeIterator() -> DocumentIterator {
        return DocumentIterator(document: self)
    }
    
    subscript(keyFor dimensions: DocumentCache.Dimensions) -> String {
        return self.readKey(atDimensions: dimensions)
    }
    
    subscript(valueFor dimensions: DocumentCache.Dimensions) -> Primitive {
        return self.readPrimitive(atDimensions: dimensions)!
    }
    
    subscript(dimensionsAt index: Int) -> DocumentCache.Dimensions {
        return self.cache.storage[index].1
    }
    
    subscript(keyAt index: Int) -> String {
        return self.cache.storage[index].0
    }
}

public struct DocumentPair {
    fileprivate let document: Document
    fileprivate let dimensions: DocumentCache.Dimensions
    
    public let index: Int
    
    public var key: String {
        return document[keyFor: dimensions]
    }
    
    public var value: Primitive {
        return document[valueFor: dimensions]
    }
}

public struct DocumentIterator: IteratorProtocol {
    fileprivate let document: Document
    fileprivate var index = 0
    
    public init(document: Document) {
        self.document = document
    }
    
    public mutating func next() -> DocumentPair? {
        guard index < self.document.count else {
            return nil
        }
        
        defer {
            index = index &+ 1
        }
        
        return DocumentPair(document: self.document, dimensions: document[dimensionsAt: index], index: index)
    }
}
