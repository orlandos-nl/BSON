extension Document: BidirectionalCollection {
    public subscript(position: DocumentIndex) -> (String, Primitive) {
        let type = typeIdentifier(at: position.offset)!

        return (
            key(at: position.offset)!,
            value(forType: type, at: position.offset)!
        )
    }
    
    public typealias Iterator = DocumentIterator
    public typealias SubSequence = DocumentSlice
    public typealias Index = DocumentIndex
    
    public var count: Int {
        var offset = 4
        var count = 0

        while skipKeyValuePair(at: &offset) {
            count += 1
        }

        return count
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
    
    /// A more detailed view into the pairs contained in this
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
    /// The index in the Document at which this pair resides
    public let index: Int
    
    /// The key associated with this pair
    public let key: String
    
    /// The value associated with this pair
    public var value: Primitive
}

public struct DocumentPairIterator: IteratorProtocol, Sequence {
    /// The Document that is being iterated over
    fileprivate let document: Document
    
    /// The next index to be returned
    public private(set) var currentIndex = 0
    
    /// If `true`, the end of this iterator has been reached
    public var isDrained: Bool {
        return count <= currentIndex
    }
    
    /// The total amount of elements in this iterator (previous, current and upcoming elements)
    public let count: Int
    
    /// Creates an iterator for a given Document
    public init(document: Document) {
        self.document = document
        self.count = document.count
    }
    
    /// Returns the next element in the Document *unless* the last element was already returned
    public mutating func next() -> DocumentPair? {
        guard currentIndex < count else { return nil }
        defer { currentIndex += 1 }

        let key = document.keys[currentIndex]
        let value = document.values[currentIndex]

        return DocumentPair(index: currentIndex, key: key, value: value)
    }
}
