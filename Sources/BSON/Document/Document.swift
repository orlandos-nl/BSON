import Foundation
import NIO

#if arch(i386) || arch(arm)
    #error("BSON does not support 32-bit platforms, PRs are welcome 🎉🐈")
#endif

// TODO: Remove when unused
func unimplemented(_ function: String = #function) -> Never {
    fatalError("\(function) is unimplemented")
}

@dynamicMemberLookup
public struct Document: Primitive {
    static let allocator = ByteBufferAllocator()
    
    /// The internal storage engine that stores BSON in it's original binary form
    /// The null terminator is missing here for performance reasons. We append it in `makeData()`
    var storage: ByteBuffer
    
    var usedCapacity: Int32 {
        get {
            guard let int = storage.getInteger(at: 0, endianness: .little, as: Int32.self) else {
                assertionFailure("Corrupted document header")
                return 0
            }
            
            return int
        }
        set {
            assert(usedCapacity >= 5)
            storage.set(integer: newValue, at: 0, endianness: .little)
        }
    }
    
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
        self.init(data: Data(bytes: [5, 0, 0, 0, 0]))
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
    internal init(storage: ByteBuffer, cache: DocumentCache, isArray: Bool) {
        self.storage = storage
        self.cache = cache
        self.isArray = isArray
    }
    
    /// Creates a new `Document` by parsing the existing `Data` buffer
    public init(data: Data, isArray: Bool = false) {
        self.storage = Document.allocator.buffer(capacity: data.count)
        self.storage.write(bytes: data)
    
        self.cache = DocumentCache()
        self.isArray = isArray
    }
    
    /// Creates a new `Document` from the given bytes
    public init(bytes: [UInt8], isArray: Bool = false) {
        self.init(data: Data(bytes: bytes), isArray: isArray)
    }
    
    /// Converts an array of Primitives to a BSON ArrayDocument
    public init(array: [Primitive]) {
        self.init(isArray: true)
        
        for element in array {
            self.append(element)
        }
    }
}
