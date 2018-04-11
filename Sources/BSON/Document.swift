import Foundation

// TODO: Remove when unused
func unimplemented() -> Never {
    fatalError("Unimplemented")
}

public struct Document: Primitive {
    var storage: Storage
    var nullTerminated: Bool
    var cache = DocumentCache()
    
    init() {
        self.init(bytes: [5, 0, 0, 0])
        self.nullTerminated = false
    }
    
    init(storage: Storage, nullTerminated: Bool) {
        self.storage = storage
        self.nullTerminated = nullTerminated
    }
    
    public init(data: Data) {
        self.storage = Storage(data: data)
        self.nullTerminated = true
    }
    
    public init(bytes: [UInt8]) {
        self.storage = Storage(bytes: bytes)
        self.nullTerminated = true
    }
    
    public init(buffer: UnsafeBufferPointer<UInt8>) {
        self.storage = Storage(buffer: buffer)
        self.nullTerminated = true
    }
}
