import Foundation

public protocol Primitive {}

public struct Document: Primitive {
    var storage: Storage
    var cache = DocumentCache()
    
    var keys: [String] {
        _ = self.scanValue(forKey: nil, startingAt: lastScannedPosition)
        let pointer = self.storage.readBuffer.baseAddress!
        
        return self.cache.storage.map { (_, dimension) in
            // + 1 for the type identifier
            let pointer = pointer.advanced(by: dimension.from &+ 1)
            return String(cString: pointer)
        }
    }
    
    init() {
        self.init(bytes: [5, 0, 0, 0, 0])
    }
    
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

extension ObjectId: Primitive {}
extension Int32: Primitive {}
extension Int64: Primitive {}
extension Double: Primitive {}
extension Bool: Primitive {}
extension String: Primitive {}

extension Optional: Primitive where Wrapped : Primitive {}
extension Optional: Primitive where Wrapped == Primitive {}
