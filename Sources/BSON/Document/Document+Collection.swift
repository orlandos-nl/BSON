extension Document: BidirectionalCollection {
    public subscript(position: DocumentIndex) -> (String, Primitive) {
        self.ensureFullyCached()
        
        let dimensions = self.cache[position.offset].dimensions
        
        let key = self.readKey(atDimensions: dimensions)
        let primitive = self.readPrimitive(atDimensions: dimensions)!
        return (key, primitive)
    }
    
    public typealias Iterator = DocumentIterator
    public typealias SubSequence = DocumentSlice
    public typealias Index = DocumentIndex
    
    public var count: Int {
        ensureFullyCached()
        
        return cache.count
    }
    
    public var startIndex: DocumentIndex {
        return DocumentIndex(offset: 0)
    }
    
    public func index(after i: DocumentIndex) -> DocumentIndex {
        return DocumentIndex(offset: i.offset + 1)
    }
    
    public func index(before i: DocumentIndex) -> DocumentIndex {
        return DocumentIndex(offset: i.offset - 1)
    }
    
    public var endIndex: DocumentIndex {
        return DocumentIndex(offset: count)
    }
    
    /// Creates an iterator that iterates over each pair in the Document
    public func makeIterator() -> DocumentIterator {
        return DocumentIterator(document: self)
    }
    
    /// A more detailed view into the pairs contained in thi.1s
    public var pairs: DocumentPairIterator {
        return DocumentPairIterator(document: self)
    }
}

public struct DocumentIndex: Comparable {
    /// The offset in the Document to look for
    var offset: Int
    
    public static func < (lhs: DocumentIndex, rhs: DocumentIndex) -> Bool {
        return lhs.offset < rhs.offset
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

public struct DocumentPairIterator: IteratorProtocol, Sequence {
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
