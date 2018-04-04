import Foundation

#if os(Linux)
import Glibc
#endif

public final class ObjectIdGenerator {
    public init() {}
    
    #if os(Linux)
        private var random: Int32 = {
            srand(UInt32(time(nil)))
            return rand()
        }()
    
        private var counter: Int32 = {
            srand(UInt32(time(nil)))
            return rand()
        }()
    #else
        private var random = arc4random_uniform(UInt32.max)
        private var counter = arc4random_uniform(UInt32.max)
    #endif
    
    public func generate() -> ObjectId {
        var bytes = [UInt8](repeating: 0, count: 12)
        
        var epoch = Int32(time(nil)).bigEndian
        
        bytes.withUnsafeMutableBufferPointer { buffer in
            let pointer = buffer.baseAddress!
            
            memcpy(pointer, &epoch, 4)
            memcpy(pointer.advanced(by: 4), &self.random, 4)
            
            // And add a counter as 2 bytes and increment it
            memcpy(pointer.advanced(by: 8), &self.counter, 4)
            self.counter = self.counter &+ 1
        }
        
        return ObjectId(Storage(bytes: bytes))
    }
}

private struct InvalidObjectIdString: Error {
    var hex: String
}

private let generator = ObjectIdGenerator()
private let lock = NSRecursiveLock()

public struct ObjectId {
    let storage: Storage
    
    init(_ storage: Storage) {
        assert(storage.usedCapacity == 12)
        
        self.storage = storage
    }
    
    init() {
        lock.lock()
        self = generator.generate()
        lock.unlock()
    }
    
    public init(_ hex: String) throws {
        guard hex.count == 24 else {
            throw InvalidObjectIdString(hex: hex)
        }
        
        var data = [UInt8]()
        data.reserveCapacity(12)
        
        var gen = hex.makeIterator()
        while let c1 = gen.next(), let c2 = gen.next() {
            let s = String([c1, c2])
            
            guard let d = UInt8(s, radix: 16) else {
                break
            }
            
            data.append(d)
        }
        
        guard data.count == 12 else {
            throw InvalidObjectIdString(hex: hex)
        }
        
        self.storage = Storage(bytes: data)
    }
    
    /// The 12 bytes represented as 24-character hex-string
    public var hexString: String {
        var data = Data()
        data.reserveCapacity(24)
        
        for byte in storage.readBuffer {
            data.append(radix16table[Int(byte / 16)])
            data.append(radix16table[Int(byte % 16)])
        }
        
        return String(data: data, encoding: .utf8)!
    }
    
    public var epochSeconds: Int32 {
        let basePointer = storage.readBuffer.baseAddress!
        
        return basePointer.withMemoryRebound(to: Int32.self, capacity: 1) { pointer in
            return pointer.pointee.bigEndian
        }
    }
    
    
    public var epoch: Date {
        return Date(timeIntervalSince1970: Double(epochSeconds))
    }
}

extension ObjectId: Hashable {
    public static func ==(lhs: ObjectId, rhs: ObjectId) -> Bool {
        for i in 0..<12 {
            guard lhs.storage.readBuffer[i] == rhs.storage.readBuffer[i] else {
                return false
            }
        }
        
        return true
    }
    
    public var hashValue: Int {
        let pointer = storage.readBuffer.baseAddress!
        
        return pointer.withMemoryRebound(to: Int32.self, capacity: 3) { pointer in
            return numericCast(pointer.pointee &+ (pointer[1] &* 3) &+ (pointer[2] &* 8))
        }
    }
}


private let radix16table: [UInt8] = [0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x61, 0x62, 0x63, 0x64, 0x65, 0x66]
