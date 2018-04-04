extension Document: Sequence {
    public var count: Int {
        _ = self.scanValue(startingAt: self.lastScannedPosition, mode: .all)
        
        return self.cache.storage.count
    }
    
    public func makeIterator() -> DocumentIterator {
        return DocumentIterator(document: self)
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
