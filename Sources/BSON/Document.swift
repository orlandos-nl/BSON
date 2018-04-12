import Foundation

// TODO: Remove when unused
func unimplemented() -> Never {
    fatalError("Unimplemented")
}

public struct Document: Primitive {
    var storage: Storage
    var nullTerminated: Bool
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
    
    public init(buffer: UnsafeBufferPointer<UInt8>, isArray: Bool = false) {
        self.storage = Storage(buffer: buffer)
        self.nullTerminated = true
        self.isArray = isArray
    }
}
