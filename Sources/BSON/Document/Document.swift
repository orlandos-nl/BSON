import Foundation

// TODO: Remove when unused
func unimplemented(_ function: String = #function) -> Never {
    fatalError("\(function) is unimplemented")
}

@dynamicMemberLookup
public struct Document: Primitive {
    /// The internal storage engine that stores BSON in it's original binary form
    /// The null terminator is missing here for performance reasons. We append it in `makeData()`
    var storage: BSONBuffer
    
    /// Dictates whether this `Document` is an `Array` or `Dictionary`-like type
    var isArray: Bool
    
    /// A cache of all elements in this BSON Document
    ///
    /// Allows high performance access with lazy parsing and low memory footprint
    let cache: DocumentCache
    
    /// Creates a new empty BSONDocument
    ///
    /// `isArray` dictates what kind of subdocument the `Document` is, and is `false` by default
    public init(isArray: Bool = false) {
        self.init(bytes: [5, 0, 0, 0, 0])
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
    internal init(storage: BSONBuffer, cache: DocumentCache, isArray: Bool) {
        self.storage = storage
        self.cache = cache
        self.isArray = isArray
    }
    
    /// Creates a new `Document` by parsing the existing `Data` buffer
    ///
    /// `isArray` dictates what kind of `Document`
    public init(data: Data, isArray: Bool = false) {
        self.storage = BSONBuffer(data: data)
        self.cache = DocumentCache()
        self.isArray = isArray
        
        if self.storage.usedCapacity > 0 {
            self.storage.removeLast(1)
        }
    }
    
    /// Creates a new `Document` by parsing the existing `[UInt8]` buffer
    ///
    /// `isArray` dictates what kind of `Document`
    public init(bytes: [UInt8], isArray: Bool = false) {
        self.storage = BSONBuffer(bytes: bytes)
        self.cache = DocumentCache()
        self.isArray = isArray
        
        if self.storage.usedCapacity > 0 {
            self.storage.removeLast(1)
        }
    }
    
    /// Assumes the buffer to not be deallocated for the duration of this Document
    ///
    /// `isArray` dictates what kind of `Document`
    ///
    /// Provides a zero-copy interface with this data, including `Codable`
    ///
    /// The buffer will only be copied on mutations of this Document
    public init(withoutCopying buffer: UnsafeBufferPointer<UInt8>, isArray: Bool = false) {
        self.storage = BSONBuffer(buffer: buffer)
        self.cache = DocumentCache()
        self.isArray = isArray
        
        if self.storage.usedCapacity > 0 {
            self.storage.removeLast(1)
        }
    }
    
    /// Converts an array of Primitives to a BSON ArrayDocument
    public init(array: [Primitive]) {
        self.init(isArray: true)
        
        for element in array {
            self.append(element)
        }
    }
    
    /// Creates a new document by copying the contents of the referenced buffer
    ///
    /// `isArray` dictates what kind of `Document`
    ///
    /// Provides a zero-copy interface with this data, including `Codable`
    ///
    /// The buffer will only be copied on mutations of this Document
    public init(copying buffer: UnsafeBufferPointer<UInt8>, isArray: Bool = false) {
        self.storage = BSONBuffer(size: buffer.count)
        self.storage.writeBuffer!.baseAddress?.assign(from: buffer.baseAddress!, count: buffer.count)
        self.storage.usedCapacity = buffer.count
        
        self.cache = DocumentCache()
        self.isArray = isArray
    }
}
