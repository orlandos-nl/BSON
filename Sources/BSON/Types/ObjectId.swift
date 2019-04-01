import Foundation
import NIO

// Documentation from MongoDB on ObjectId can be found in this comment:
// https://github.com/mongodb/mongo/blob/e5c39e225effd4a28937c32c84ac3dc0c1ceb355/src/mongo/bson/oid.h#L43
//
// Note that the spec (as of version 0.2) of ObjectID contradicts this:
// https://github.com/mongodb/specifications/blob/6a31988385f54e4ec9daddfbf21344a2a96e2656/source/objectid.rst

fileprivate let processIdentifier = ProcessInfo.processInfo.processIdentifier

// ObjectIdGenerator subclasses NSObject so it can be used in the thread dictionary on Linux
public final class ObjectIdGenerator: NSObject {
    private var template: ContiguousArray<UInt8>
    
    public override init() {
        self.template = ContiguousArray<UInt8>(repeating: 0, count: 12)
        
        template.withUnsafeMutableBytes { buffer in
            // 4 bytes of epoch time, will be unique for each ObjectId, set on creation
            
            // then 5 bytes of random value
            // yes, the code below writes 4 bytes, but the last one will be overwritten by the process id
            let randomBytes = UInt32.random(in: UInt32.min...UInt32.max)
            buffer.baseAddress!.advanced(by: 4).assumingMemoryBound(to: UInt32.self).pointee = randomBytes
            
            // last 3 bytes: random counter
            // this will also write 4 bytes, at index 8, while the counter actually starts at index 9
            // the process id will overwrite the first byte
            let randomByteAndInitialCounter = UInt32.random(in: UInt32.min...UInt32.max)
            buffer.baseAddress!.advanced(by: 8).assumingMemoryBound(to: UInt32.self).pointee = randomByteAndInitialCounter
        }
    }
    
    // TODO: Make this in line with the MongoDB implementation (big endian)
    func incrementTemplateCounter() {
        template.withUnsafeMutableBytes { buffer in
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
        defer { self.incrementTemplateCounter() }
        
        var template = self.template
        
        template.withUnsafeMutableBytes { buffer in
            // Unlike the rest of BSON, the timestamp is big endian
            buffer.bindMemory(to: Int32.self).baseAddress!.pointee = Int32(time(nil)).bigEndian
        }
        
        return ObjectId(template)
    }
}

/// An error that occurs if the ObjectId was initialized with an invalid HexString
private struct InvalidObjectIdString: Error {
    var hex: String
}

public struct ObjectId {
    /// The internal Storage Buffer
    let storage: ContiguousArray<UInt8>
    
    /// Creates a new ObjectId using exsiting data
    init(_ storage: ContiguousArray<UInt8>) {
        self.storage = storage
    }
 
    public init() {
        if let generator = Thread.current.threadDictionary["_BSON_ObjectId_Generator"] as? ObjectIdGenerator { 
            self = generator.generate()
        } else {
            let generator = ObjectIdGenerator()
            Thread.current.threadDictionary["_BSON_ObjectId_Generator"] = generator
            self = generator.generate()
        }
    }
    
    /// Decodes the ObjectID from the provided (24 character) hexString
    public init(_ hex: String) throws {
        guard hex.count == 24 else {
            throw InvalidObjectIdString(hex: hex)
        }
        
        var storage = ContiguousArray<UInt8>()
        storage.reserveCapacity(12)
        
        var gen = hex.makeIterator()
        while let c1 = gen.next(), let c2 = gen.next() {
            let s = String([c1, c2])
            
            guard let d = UInt8(s, radix: 16) else {
                break
            }
            
            storage.append(d)
        }
        
        guard storage.count == 12 else {
            throw InvalidObjectIdString(hex: hex)
        }
        
        self.storage = storage
    }
    
    /// The 12 bytes represented as 24-character hex-string
    public var hexString: String {
        var data = Data()
        data.reserveCapacity(24)
        
        func transform(_ byte: UInt8) {
            data.append(radix16table[Int(byte / 16)])
            data.append(radix16table[Int(byte % 16)])
        }
        
        for byte in storage {
            transform(byte)
        }
        
        return String(data: data, encoding: .utf8)!
    }
    
    /// Returns the ObjectId's creation date in UNIX epoch seconds
    public var timestamp: Int32 {
        return storage.withUnsafeBytes { buffer in
            // Unlike the rest of BSON, the timestamp is big endian
            return Int32(bigEndian: buffer.bindMemory(to: Int32.self).baseAddress!.pointee)
        }
    }
    
    /// The creation date of this ObjectId
    public var date: Date {
        return Date(timeIntervalSince1970: .init(timestamp))
    }
}

extension ObjectId: Hashable {
    public static func ==(lhs: ObjectId, rhs: ObjectId) -> Bool {
        return lhs.storage == rhs.storage
    }
    
    public func hash(into hasher: inout Hasher) {
        storage.hash(into: &hasher)
    }
}

extension ObjectId: CustomStringConvertible {
    public var description: String {
        return self.hexString
    }
}

fileprivate let radix16table: [UInt8] = [0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x61, 0x62, 0x63, 0x64, 0x65, 0x66]
