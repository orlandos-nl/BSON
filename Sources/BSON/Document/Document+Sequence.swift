extension Document: Sequence {
    /// Returns the amount of top-level elements
    public var count: Int {
        ensureFullyCached()
        
        return cache.count
    }
    
    /// Creates an iterator that iterates over each element in the Document until the end
    public func makeIterator() -> AnyIterator<(String, Primitive)> {
        var pairs = self.pairs
        
        return AnyIterator {
            guard let pair = pairs.next() else {
                return nil
            }
            
            return (pair.key, pair.value)
        }
    }
    
    /// A more detailed view into the pairs contained in thi.1s
    public var pairs: DocumentIterator {
        return DocumentIterator(document: self)
    }
}

/// A key-value pair from a Document
///
/// Contains all metadata for a given Pair
public struct DocumentPair {
    /// The referenced Document
    fileprivate let document: Document
    
    /// The dimensions in the Document to look for
    fileprivate let dimensions: DocumentCache.Dimensions
    
    /// The type identifer of the value
    internal var identifier: TypeIdentifier {
        return dimensions.type
    }
    
    /// The index in the Document at which this pair resides
    public let index: Int
    
    /// The key associated with this pair
    public var key: String {
        return document.readKey(atDimensions: dimensions)
    }
    
    /// The value associated with this pair
    public var value: Primitive {
        return document[valueFor: dimensions]
    }
}

public struct DocumentIterator: IteratorProtocol, Sequence {
    /// The Document that is being iterated over
    fileprivate let document: Document
    
    /// The next index to be returned
    public private(set) var currentIndex = 0
    
    /// If `true`, the end of this iterator has been reached
    public var isDrained: Bool {
        return self.document.count <= currentIndex
    }
    
    /// The total amount of elements in this iterator (previous, current and upcoming elements)
    public var count: Int {
        return self.document.count
    }
    
    /// Creates an iterator for a given Document
    public init(document: Document) {
        self.document = document
    }
    
    /// Returns the next element in the Document *unless* the last element was already returned
    public mutating func next() -> DocumentPair? {
        guard currentIndex < self.document.count else {
            return nil
        }
        
        defer {
            currentIndex = currentIndex &+ 1
        }
        
        return DocumentPair(
            document: self.document,
            dimensions: document.cache[currentIndex].1,
            index: currentIndex
        )
    }
}
