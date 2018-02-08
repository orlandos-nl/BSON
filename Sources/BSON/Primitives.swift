import Foundation

public struct Document {
    var storage: Storage
    
    init(storage: Storage) {
        self.storage = storage
    }
    
    public init(data: Data) {
        self.storage = Storage(data: data)
    }
    
    public init(bytes: [UInt8]) {
        self.storage = Storage(bytes: bytes)
    }
    
    public init(buffer: UnsafeBufferPointer<UInt8>) {
        self.storage = Storage(buffer: buffer)
    }
}
