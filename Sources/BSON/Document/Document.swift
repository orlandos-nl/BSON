import Foundation
import NIO

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
            Swift.assert(usedCapacity >= 5)
            storage.setInteger(newValue, at: 0, endianness: .little)
        }
    }
    
    /// Dictates whether this `Document` is an `Array` or `Dictionary`-like type
    public internal(set) var isArray: Bool

    /// Creates a new empty BSONDocument
    ///
    /// `isArray` dictates what kind of subdocument the `Document` is, and is `false` by default
    public init(isArray: Bool = false) {
        var buffer = Document.allocator.buffer(capacity: 4_096)
        buffer.writeInteger(Int32(5), endianness: .little)
        buffer.writeInteger(UInt8(0), endianness: .little)
        self.storage = buffer
        self.isArray = isArray
    }
    
    /// Creates a new `Document` by parsing an existing `ByteBuffer`
    public init(buffer: ByteBuffer, isArray: Bool = false) {
        self.storage = buffer
        self.isArray = isArray
    }
    
    /// Creates a new `Document` by parsing the existing `Data` buffer
    public init(data: Data, isArray: Bool = false) {
        self.storage = Document.allocator.buffer(capacity: data.count)
        self.storage.writeBytes(data)
        self.isArray = isArray
    }
    
    /// Creates a new `Document` from the given bytes
    public init(bytes: [UInt8], isArray: Bool = false) {
        self.storage = Document.allocator.buffer(capacity: bytes.count)
        self.storage.writeBytes(bytes)
        self.isArray = isArray
    }
}
