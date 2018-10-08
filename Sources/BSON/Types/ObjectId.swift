import Foundation
import NIO

fileprivate let processIdentifier = ProcessInfo.processInfo.processIdentifier

public final class ObjectIdGenerator {
    // TODO: is a different MachineIdentifier per ObjectIdGenerator acceptable?
    let machineIdentifier = UInt32.random(in: UInt32.min...UInt32.max)
    
    private var template: ContiguousArray<UInt8>
    
    public init() {
        self.template = ContiguousArray<UInt8>(repeating: 0, count: 12)
        
        withUnsafeMutableBytes(of: &template) { buffer in
            // 4 bytes of epoch time, will be unique for each ObjectId, set on creation
            
            // then 3 bytes of machine identifier
            // yes, the code below writes 4 bytes, but the last one will be overwritten by the process id
            buffer.baseAddress!.advanced(by: 4).assumingMemoryBound(to: UInt32.self).pointee = machineIdentifier.littleEndian
            
            // last 3 bytes: random counter
            // this will also write 4 bytes, at index 8, while the counter actually starts at index 9
            // the process id will overwrite the first byte
            let initialCounter = UInt32.random(in: UInt32.min...UInt32.max)
            buffer.baseAddress!.advanced(by: 8).assumingMemoryBound(to: UInt32.self).pointee = initialCounter.littleEndian
            
            // process id - UInt16
            buffer.baseAddress!.advanced(by: 7).assumingMemoryBound(to: Int32.self).pointee = processIdentifier.littleEndian
        }
    }
    
    func incrementTemplateCounter() {
        self.template.withUnsafeMutableBytes { buffer in
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
            buffer.bindMemory(to: Int32.self).baseAddress!.pointee = Int32(time(nil)).littleEndian
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
    let storage: ContiguousArray<UInt8>
    
    /// Creates a new ObjectId using exsiting data
    init(_ storage: ContiguousArray<UInt8>) {
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
    public var epochSeconds: Int32 {
        return storage.withUnsafeBytes { buffer in
            return buffer.bindMemory(to: Int32.self).baseAddress!.pointee
        }
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
        storage.hash(into: &hasher)
    }
}

extension ObjectId: CustomStringConvertible {
    public var description: String {
        return self.hexString
    }
}

fileprivate let radix16table: [UInt8] = [0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x61, 0x62, 0x63, 0x64, 0x65, 0x66]
