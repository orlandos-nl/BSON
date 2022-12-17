public struct DocumentSlice: RandomAccessCollection, MutableCollection {
    public func index(before i: DocumentIndex) -> DocumentIndex {
        return DocumentIndex(offset: i.offset - 1)
    }
    
    public func index(after i: DocumentIndex) -> DocumentIndex {
        return DocumentIndex(offset: i.offset + 1)
    }
    
    public subscript(position: DocumentIndex) -> (String, Primitive) {
        get { document[position] }
        set {
            guard let key = document.getKey(at: position.offset) else {
                fatalError("Attempting to change a value out of bounds")
            }
            
            if key == newValue.0 {
                // Same key, just change the value
                document[key] = newValue.1
            } else {
                document[key] = nil
                document[newValue.0] = newValue.1
            }
        }
    }
    
    public subscript(bounds: Range<DocumentIndex>) -> DocumentSlice {
        get {
            DocumentSlice(document: document, startIndex: bounds.lowerBound, endIndex: bounds.upperBound)
        }
        set {
            document[bounds] = newValue
        }
    }
    
    public typealias Element = (String, Primitive)
    public typealias SubSequence = DocumentSlice
    
    /// The Document that is being sliced
    var document: Document

    /// The index of the first element in the slice
    public let startIndex: DocumentIndex

    /// The index after the last element in the slice
    public let endIndex: DocumentIndex
}

public struct DocumentIterator: IteratorProtocol {
    /// The Document that is being iterated over
    fileprivate let document: Document
    
    /// The next index to be returned
    private var currentIndex = 0
    private var currentBinaryIndex = 4
    
    /// If `true`, the end of this iterator has been reached
    private var isDrained: Bool {
        return count <= currentIndex
    }
    
    /// The total amount of elements in this iterator (previous, current and upcoming elements)
    private let count: Int
    
    /// Creates an iterator for a given Document
    public init(document: Document) {
        self.document = document
        self.count = document.count
    }
    
    /// Returns the next element in the Document *unless* the last element was already returned
    public mutating func next() -> (String, Primitive)? {
        guard currentIndex < count else { return nil }
        defer { currentIndex += 1 }

        guard
            let typeByte = document.storage.getByte(at: currentBinaryIndex),
            let type = TypeIdentifier(rawValue: typeByte)
        else {
            return nil
        }
        
        currentBinaryIndex += 1
        
        guard
            let key = document.getKey(at: currentBinaryIndex),
            document.skipKey(at: &currentBinaryIndex),
            let valueLength = document.valueLength(forType: type, at: currentBinaryIndex),
            let value = document.value(forType: type, at: currentBinaryIndex)
        else {
            return nil
        }
        
        currentBinaryIndex += valueLength
        
        return (key, value)
    }
}


extension Document {
    func pair(atIndex index: DocumentIndex) -> (String, Primitive)? {
        guard index.offset < count else { return nil }

        return (keys[index.offset], values[index.offset])
    }
}
