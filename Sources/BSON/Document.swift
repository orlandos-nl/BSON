import Foundation

// TODO: Remove when unused
func unimplemented() -> Never {
    fatalError("Unimplemented")
}

public struct Document: Primitive {
    /// The internal storage engine that stores BSON in it's original binary fomr
    var storage: Storage
    
    /// Indicates that the `Document` holds the final null terminator
    ///
    /// If omitted, the performance for appends will increase until serialization
    var nullTerminated: Bool
    
    /// 
    var isArray: Bool
    var cache = DocumentCache()
    
    public init(isArray: Bool = false) {
        self.init(bytes: [5, 0, 0, 0])
        self.nullTerminated = false
        self.isArray = isArray
    }
    
    init(storage: Storage, nullTerminated: Bool, isArray: Bool) {
        self.storage = storage
        self.nullTerminated = nullTerminated
        self.isArray = isArray
    }
    
    public init(data: Data, isArray: Bool = false) {
        self.storage = Storage(data: data)
        self.nullTerminated = true
        self.isArray = isArray
    }
    
    public init(bytes: [UInt8], isArray: Bool = false) {
        self.storage = Storage(bytes: bytes)
        self.nullTerminated = true
        self.isArray = isArray
    }
    
    /// Assumes the buffer to not be deallocated for the duration of this Document
    ///
    /// Provides a zero-copy interface with this data, including `Codable`
    ///
    /// The buffer will only be copied on mutations of this Document
    public init(buffer: UnsafeBufferPointer<UInt8>, isArray: Bool = false) {
        self.storage = Storage(buffer: buffer)
        self.nullTerminated = true
        self.isArray = isArray
    }
}
