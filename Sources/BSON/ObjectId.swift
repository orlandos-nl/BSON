import Foundation

#if os(Linux)
import Glibc

fileprivate var machineIdentifier: UInt32 = numericCast(srand(UInt32(time(nil))))
#else
fileprivate var machineIdentifier: UInt32 = arc4random_uniform(UInt32.max)
#endif


fileprivate var currentIdentifier: UInt16 = 0
let lock = NSRecursiveLock()

fileprivate var nextIdentifer: UInt16 {
    defer {
        lock.lock()
        currentIdentifier = currentIdentifier &+ 1
        lock.unlock()
    }
    
    return currentIdentifier
}

public final class ObjectIdGenerator {
    public init() {
        var template = [UInt8](repeating: 0, count: 12)
        
        template.withUnsafeMutableBufferPointer { buffer in
            let pointer = buffer.baseAddress!
            
            // 4 bytes of epoch
            memcpy(pointer.advanced(by: 4), &machineIdentifier, 3)
            
            pointer.advanced(by: 4).withMemoryRebound(to: UInt32.self, capacity: 1) { pointer in
                pointer.pointee = machineIdentifier
            }
            
            pointer.advanced(by: 7).withMemoryRebound(to: UInt16.self, capacity: 1) { pointer in
                pointer.pointee = nextIdentifer
            }
            
            #if os(Linux)
            var random: UInt32 = numericCast(srand(UInt32(time(nil))))
            #else
            var random: UInt32 = arc4random_uniform(UInt32.max)
            #endif
            
            withUnsafePointer(to: &random) { randomPointer in
                randomPointer.withMemoryRebound(to: UInt8.self, capacity: 3) { randomPointer in
                    pointer.advanced(by: 9).assign(from: randomPointer, count: 3)
                }
            }
        }
        
        self.template = template
    }
    
    func incrementTemplateCounter() {
        self.template.withUnsafeMutableBytes { buffer in
            let pointer = buffer.baseAddress!.assumingMemoryBound(to: UInt8.self)
            
            // Need to simulate an (U)Int24
            pointer[11] = pointer[11] &+ 1
            
            if pointer[11] == 0 {
                pointer[10] = pointer[10] &+ 1
                
                if pointer[10] == 0 {
                    pointer[9] = pointer[9] &+ 1
                }
            }
        }
    }
    
    private var template: [UInt8]
    
    /// Generates a new ObjectId
    public func generate() -> ObjectId {
        var template = self.template
        
        template.withUnsafeMutableBufferPointer { buffer in
            buffer.baseAddress!.withMemoryRebound(to: Int32.self, capacity: 1) { pointer in
                pointer.pointee = Int32(time(nil)).bigEndian
            }
        }
        
        self.incrementTemplateCounter()
        
        return ObjectId(Storage(bytes: template))
    }
}

/// An error that occurs if the ObjectId was initialized with an invalid HexString
private struct InvalidObjectIdString: Error {
    var hex: String
}

public struct ObjectId {
    /// The internal Storage Buffer
    let storage: Storage
    
    /// Creates a new ObjectId using an existing (Sub-)Storage buffer
    init(_ storage: Storage) {
        assert(storage.usedCapacity == 12)
        
        self.storage = storage
    }
    
    /// Decodes the ObjectID from the provided (24 character) hexString
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
    
    /// Returns the ObjectId's creation date in UNIX epoch seconds
    public var epochSeconds: Int32 {
        let basePointer = storage.readBuffer.baseAddress!
        
        return basePointer.withMemoryRebound(to: Int32.self, capacity: 1) { pointer in
            return pointer.pointee.bigEndian
        }
    }
    
    /// The creation date of this ObjectId
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

fileprivate let radix16table: [UInt8] = [0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x61, 0x62, 0x63, 0x64, 0x65, 0x66]
