import Foundation
import NIO

fileprivate let processIdentifier = ProcessInfo.processInfo.processIdentifier

public final class ObjectIdGenerator {
    private var template: Data
    
    public init() {
        self.template = Data(count: 12)
        
        template.withUnsafeMutableBytes { (pointer: UnsafeMutablePointer<UInt8>) in
            // 4 bytes of epoch time, will be unique for each ObjectId, set on creation
            
            // then 5 bytes of random value
            // yes, the code below writes 4 bytes, but the last one will be overwritten by the process id
            let randomBytes = UInt32.random(in: UInt32.min...UInt32.max)
            pointer.advanced(by: 4).withMemoryRebound(to: UInt32.self, capacity: 1) { randomPointer in
                randomPointer.pointee = randomBytes
            }
            
            // last 3 bytes: random counter
            // this will also write 4 bytes, at index 8, while the counter actually starts at index 9
            // the process id will overwrite the first byte
            let randomByteAndInitialCounter = UInt32.random(in: UInt32.min...UInt32.max)
            pointer.advanced(by: 8).withMemoryRebound(to: UInt32.self, capacity: 1) { counterPointer in
                counterPointer.pointee = randomByteAndInitialCounter
            }
        }
    }
    
    func incrementTemplateCounter() {
        // Need to simulate an (U)Int24
        template[11] = template[11] &+ 1
        
        if template[11] == 0 {
            template[10] = template[10] &+ 1
            
            if template[10] == 0 {
                template[9] = template[9] &+ 1
            }
        }
    }
    
    /// Generates a new ObjectId
    public func generate() -> ObjectId {
        defer { self.incrementTemplateCounter() }
        
        var template = self.template
        template.withUnsafeMutableBytes { (pointer: UnsafeMutablePointer<UInt32>) in
            pointer.pointee = UInt32(time(nil)).littleEndian
        }
        
        return ObjectId(template)
    }
}

/// An error that occurs if the ObjectId was initialized with an invalid HexString
private struct InvalidObjectIdString: Error {
    var hex: String
}

typealias RawObjectId = (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8)

public struct ObjectId {
    /// The internal Storage Buffer
    let storage: Data
    
    /// Creates a new ObjectId using exsiting data
    init(_ storage: Data) {
        self.storage = storage
    }
 
    // TODO: Implement this another way, perhaps with a generator per thread
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
        
        var storage = Data()
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
    public var timestamp: UInt32 {
        return storage.withUnsafeBytes { (pointer: UnsafePointer<UInt32>) in
            return UInt32(littleEndian: pointer.pointee)
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
