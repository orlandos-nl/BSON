import Foundation

// TODO: Remove when unused
func unimplemented() -> Never {
    fatalError("Unimplemented")
}

public struct Document: Primitive {
    /// The internal storage engine that stores BSON in it's original binary fomr
    var storage: BSONBuffer
    
    /// Indicates that the `Document` holds the final null terminator
    ///
    /// If omitted, the performance for appends will increase until serialization
    var nullTerminated: Bool
    
    /// Dictates whether this `Document` is an `Array` or `Dictionary-like` type
    var isArray: Bool
    
    /// A cache of all elements in this BSON Document
    ///
    /// Allows high performance access with lazy parsing and low-memory footprint
    let cache: DocumentCache
    
    /// Creates a new empty BSONDocument
    ///
    /// `isArray` dictates what kind of `Document` and is `false` by default
    public init(isArray: Bool = false) {
        self.init(bytes: [5, 0, 0, 0])
        self.nullTerminated = false
        self.isArray = isArray
    }
    
    /// Creates a new `Document` based on an existing `Storage`
    ///
    /// `isArray` dictates what kind of `Document`
    ///
    /// If `nullTerminated` is true the Document is exactly according to spec
    /// If it's `false`, the final `nullTerminator` is ommitted from this Document allowing more efficient `appends`
    ///
    /// The `cache` provided can be empty if nothing is cached yet or can be used as a shortcut
    internal init(storage: BSONBuffer, cache: DocumentCache, nullTerminated: Bool, isArray: Bool) {
        self.storage = storage
        self.nullTerminated = nullTerminated
        self.cache = cache
        self.isArray = isArray
    }
    
    /// Creates a new `Document` by parsing the existing `Data` buffer
    ///
    /// `isArray` dictates what kind of `Document`
    public init(data: Data, isArray: Bool = false) {
        self.storage = BSONBuffer(data: data)
        self.nullTerminated = true
        self.cache = DocumentCache()
        self.isArray = isArray
    }
    
    /// Creates a new `Document` by parsing the existing `[UInt8]` buffer
    ///
    /// `isArray` dictates what kind of `Document`
    public init(bytes: [UInt8], isArray: Bool = false) {
        self.storage = BSONBuffer(bytes: bytes)
        self.nullTerminated = true
        self.cache = DocumentCache()
        self.isArray = isArray
    }
    
    /// Creates a thread unsafe Document using a predefined `BSONArenaAllocator` allowing extremely cheap BSON operations
    ///
    /// `isArray` dictates what kind of `Document`
    public init(allocator: BSONArenaAllocator, isArray: Bool = false) {
        self.storage = BSONBuffer(allocating: 4, allocator: allocator)
        self.nullTerminated = true
        self.cache = DocumentCache()
        self.isArray = isArray
    }
    
    /// Assumes the buffer to not be deallocated for the duration of this Document
    ///
    /// `isArray` dictates what kind of `Document`
    ///
    /// Provides a zero-copy interface with this data, including `Codable`
    ///
    /// The buffer will only be copied on mutations of this Document
    public init(buffer: UnsafeBufferPointer<UInt8>, isArray: Bool = false) {
        self.storage = BSONBuffer(buffer: buffer)
        self.nullTerminated = true
        self.cache = DocumentCache()
        self.isArray = isArray
    }
}
