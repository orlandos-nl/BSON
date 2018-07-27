import Foundation
import NIO

fileprivate let processIdentifier = ProcessInfo.processInfo.processIdentifier

public final class ObjectIdGenerator {
    // TODO: is a different MachineIdentifier per ObjectIdGenerator acceptable?
    let machineIdentifier = UInt32.random(in: UInt32.min...UInt32.max)
    
    private var template: ByteBuffer
    
    public init() {
        self.template = Document.allocator.buffer(capacity: 12)
        
        // 4 bytes of epoch time, will be unique for each ObjectId
        
        // then 3 bytes of machine identifier
        // yes, the code below writes 4 bytes, but the last one will be overwritten by the process id
        template.set(integer: machineIdentifier, at: 4, endianness: .little)
        
        // last 3 bytes: random counter
        // this will also write 4 bytes, at index 8, while the counter actually starts at index 9
        // the process id will overwrite the first byte
        let initialCounter = UInt32.random(in: UInt32.min...UInt32.max)
        template.set(integer: initialCounter, at: 8, endianness: .little)
        
        // process id
        template.set(integer: processIdentifier, at: 7, endianness: .little)
    }
    
    func incrementTemplateCounter() {
        template.moveReaderIndex(to: 0)
        template.moveWriterIndex(to: 12)
        
        self.template.withUnsafeMutableReadableBytes { buffer in
            // Need to simulate an (U)Int24
            buffer[11] = buffer[11] &+ 1
            
            if buffer[11] == 0 {
                buffer[10] = buffer[10] &+ 1
                
                if buffer[10] == 0 {
                    buffer[9] = buffer[9] &+ 1
                }
            }
        }
    }
    
    /// Generates a new ObjectId
    public func generate() -> ObjectId {
        var template = self.template
        
        // TODO: big or little endian?
        template.set(integer: Int32(time(nil)), at: 0, endianness: .little)
        
        self.incrementTemplateCounter()
        
        template.moveWriterIndex(to: 12)
        return ObjectId(template)
    }
}

/// An error that occurs if the ObjectId was initialized with an invalid HexString
private struct InvalidObjectIdString: Error {
    var hex: String
}

public struct ObjectId {
    /// The internal Storage Buffer
    let storage: ByteBuffer
    
    /// Creates a new ObjectId using exsiting data
    init(_ storage: ByteBuffer) {
        Swift.assert(storage.readableBytes == 12)
        
        self.storage = storage
    }
 
    // TODO: Implement this another way
    public init() {
        self = ObjectIdGenerator().generate()
    }
    
    /// Decodes the ObjectID from the provided (24 character) hexString
    public init(_ hex: String) throws {
        guard hex.count == 24 else {
            throw InvalidObjectIdString(hex: hex)
        }
        
        var storage = Document.allocator.buffer(capacity: 12)
        
        var gen = hex.makeIterator()
        while let c1 = gen.next(), let c2 = gen.next() {
            let s = String([c1, c2])
            
            guard let d = UInt8(s, radix: 16) else {
                break
            }
            
            storage.write(integer: d, endianness: .little)
        }
        
        guard storage.readableBytes == 12 else {
            throw InvalidObjectIdString(hex: hex)
        }
        
        self.storage = storage
    }
    
    /// The 12 bytes represented as 24-character hex-string
    public var hexString: String {
        var data = Data()
        data.reserveCapacity(24)
        
        for byte in storage.getBytes(at: 0, length: 12)! {
            data.append(radix16table[Int(byte / 16)])
            data.append(radix16table[Int(byte % 16)])
        }
        
        return String(data: data, encoding: .utf8)!
    }
    
    /// Returns the ObjectId's creation date in UNIX epoch seconds
    public var epochSeconds: Int32 {
        return storage.getInteger(at: 0, endianness: .little)!
    }
    
    /// The creation date of this ObjectId
    public var epoch: Date {
        return Date(timeIntervalSince1970: Double(epochSeconds))
    }
}

extension ObjectId: Hashable {
    public static func ==(lhs: ObjectId, rhs: ObjectId) -> Bool {
        return lhs.storage == rhs.storage
    }
    
    public func hash(into hasher: inout Hasher) {
        storage.withUnsafeReadableBytes {
            hasher.combine(bytes: $0)
        }
    }
}

fileprivate let radix16table: [UInt8] = [0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x61, 0x62, 0x63, 0x64, 0x65, 0x66]
