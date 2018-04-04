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
    
    internal var identifier: UInt8 {
        return dimensions.type
    }
    
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
    public private(set) var currentIndex = 0
    public var isDrained: Bool {
        return self.document.count > currentIndex
    }
    
    public var count: Int {
        return self.document.count
    }
    
    public init(document: Document) {
        self.document = document
    }
    
    public mutating func next() -> DocumentPair? {
        guard currentIndex < self.document.count else {
            return nil
        }
        
        defer {
            currentIndex = currentIndex &+ 1
        }
        
        return DocumentPair(
            document: self.document,
            dimensions: document[dimensionsAt: currentIndex],
            index: currentIndex
        )
    }
}
