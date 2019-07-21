import Foundation
import NIO

// Documentation from MongoDB on ObjectId can be found in this comment:
// https://github.com/mongodb/mongo/blob/e5c39e225effd4a28937c32c84ac3dc0c1ceb355/src/mongo/bson/oid.h#L43
//
// Note that the spec (as of version 0.2) of ObjectID contradicts this:
// https://github.com/mongodb/specifications/blob/6a31988385f54e4ec9daddfbf21344a2a96e2656/source/objectid.rst

fileprivate let processIdentifier = ProcessInfo.processInfo.processIdentifier

// TODO: Struct
public final class ObjectIdGenerator {
    private static var threadSpecificGenerator = ThreadSpecificVariable<ObjectIdGenerator>()
    private let byte4: UInt8
    private let byte5: UInt8
    private let byte6: UInt8
    private let byte7: UInt8
    private let byte8: UInt8
    private var byte9: UInt8
    private var byte10: UInt8
    private var byte11: UInt8
    
    /// Returns the `ObjectIdGenerator` for the current thread
    ///
    /// - warning: Note that `ObjectIdGenerator` in itself is not thread-safe. It is advised not to store the value that results from accessing this property. Instead, use it directly: `ObjectIdGenerator.default.generate()`
    public static var `default`: ObjectIdGenerator {
        if let generator = threadSpecificGenerator.currentValue {
            return generator
        }
        
        let generator = ObjectIdGenerator()
        threadSpecificGenerator.currentValue = generator
        return generator
    }
    
    public init() {
        // 4 bytes of epoch time, will be unique for each ObjectId, set on creation

        // then 5 bytes of random value
        // yes, the code below writes 4 bytes, but the last one will be overwritten by the process id
        let randomBytes = UInt32.random(in: UInt32.min...UInt32.max)
        byte4 = UInt8(truncatingIfNeeded: randomBytes >> 24)
        byte5 = UInt8(truncatingIfNeeded: randomBytes >> 16)
        byte6 = UInt8(truncatingIfNeeded: randomBytes >> 8)
        byte7 = UInt8(truncatingIfNeeded: randomBytes)

        // last 3 bytes: random counter
        // this will also write 4 bytes, at index 8, while the counter actually starts at index 9
        // the process id will overwrite the first byte
        let randomByteAndInitialCounter = UInt32.random(in: UInt32.min...UInt32.max)
        byte8 = UInt8(truncatingIfNeeded: randomByteAndInitialCounter >> 24)
        byte9 = UInt8(truncatingIfNeeded: randomByteAndInitialCounter >> 16)
        byte10 = UInt8(truncatingIfNeeded: randomByteAndInitialCounter >> 8)
        byte11 = UInt8(truncatingIfNeeded: randomByteAndInitialCounter)
    }
    
    // TODO: Make this in line with the MongoDB implementation (big endian)
    func incrementTemplateCounter() {
        // Need to simulate an (U)Int24
        byte11 = byte11 &+ 1

        if byte11 == 0 {
            byte10 = byte10 &+ 1

            if byte10 == 0 {
                byte9 = byte9 &+ 1
            }
        }
    }
    
    /// Generates a new ObjectId
    public func generate() -> ObjectId {
        defer { self.incrementTemplateCounter() }

        let timestamp = Int32(time(nil)).bigEndian

        let byte0 = UInt8(truncatingIfNeeded: timestamp >> 24)
        let byte1 = UInt8(truncatingIfNeeded: timestamp >> 16)
        let byte2 = UInt8(truncatingIfNeeded: timestamp >> 8)
        let byte3 = UInt8(truncatingIfNeeded: timestamp)

        return ObjectId(byte0, byte1, byte2, byte3, byte4, byte5, byte6, byte7, byte8, byte9, byte10, byte11)
    }
}

/// An error that occurs if the ObjectId was initialized with an invalid HexString
private struct InvalidObjectIdString: Error {
    var hex: String
}

public struct ObjectId {
    // TODO: Swift 5.1 SIMD
    /// The internal Storage Buffer
    let byte0: UInt8
    let byte1: UInt8
    let byte2: UInt8
    let byte3: UInt8
    let byte4: UInt8
    let byte5: UInt8
    let byte6: UInt8
    let byte7: UInt8
    let byte8: UInt8
    let byte9: UInt8
    let byte10: UInt8
    let byte11: UInt8
 
    public init() {
        self = ObjectIdGenerator.default.generate()
    }

    public init(
        _ byte0: UInt8, _ byte1: UInt8, _ byte2: UInt8, _ byte3: UInt8,
        _ byte4: UInt8, _ byte5: UInt8, _ byte6: UInt8, _ byte7: UInt8,
        _ byte8: UInt8, _ byte9: UInt8, _ byte10: UInt8, _ byte11: UInt8
    ) {
        self.byte0 = byte0
        self.byte1 = byte1
        self.byte2 = byte2
        self.byte3 = byte3
        self.byte4 = byte4
        self.byte5 = byte5
        self.byte6 = byte6
        self.byte7 = byte7
        self.byte8 = byte8
        self.byte9 = byte9
        self.byte10 = byte10
        self.byte11 = byte11
    }

    internal init(storage: ContiguousArray<UInt8>) {
        Swift.assert(storage.count == 12)

        byte0 = storage[0]
        byte1 = storage[1]
        byte2 = storage[2]
        byte3 = storage[3]
        byte4 = storage[4]
        byte5 = storage[5]
        byte6 = storage[6]
        byte7 = storage[7]
        byte8 = storage[8]
        byte9 = storage[9]
        byte10 = storage[10]
        byte11 = storage[11]
    }

    internal init(storage: Array<UInt8>) {
        Swift.assert(storage.count == 12)

        byte0 = storage[0]
        byte1 = storage[1]
        byte2 = storage[2]
        byte3 = storage[3]
        byte4 = storage[4]
        byte5 = storage[5]
        byte6 = storage[6]
        byte7 = storage[7]
        byte8 = storage[8]
        byte9 = storage[9]
        byte10 = storage[10]
        byte11 = storage[11]
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
        
        self.byte0 = storage[0]
        self.byte1 = storage[1]
        self.byte2 = storage[2]
        self.byte3 = storage[3]
        self.byte4 = storage[4]
        self.byte5 = storage[5]
        self.byte6 = storage[6]
        self.byte7 = storage[7]
        self.byte8 = storage[8]
        self.byte9 = storage[9]
        self.byte10 = storage[10]
        self.byte11 = storage[11]
    }
    
    /// The 12 bytes represented as 24-character hex-string
    public var hexString: String {
        var data = Data()
        data.reserveCapacity(24)
        
        func transform(_ byte: UInt8) {
            data.append(radix16table[Int(byte / 16)])
            data.append(radix16table[Int(byte % 16)])
        }
        
        transform(byte0)
        transform(byte1)
        transform(byte2)
        transform(byte3)
        transform(byte4)
        transform(byte5)
        transform(byte6)
        transform(byte7)
        transform(byte8)
        transform(byte9)
        transform(byte10)
        transform(byte11)
        
        return String(data: data, encoding: .utf8)!
    }
    
    /// Returns the ObjectId's creation date in UNIX epoch seconds
    public var timestamp: Int32 {
        var timestamp: Int32 = 0
        timestamp |= (numericCast(byte0) << 24)
        timestamp |= (numericCast(byte1) << 16)
        timestamp |= (numericCast(byte2) << 8)
        timestamp |= (numericCast(byte3))
        return Int32(bigEndian: timestamp)
    }
    
    /// The creation date of this ObjectId
    public var date: Date {
        return Date(timeIntervalSince1970: .init(timestamp))
    }
}

extension ObjectId: Hashable {
    public static func ==(lhs: ObjectId, rhs: ObjectId) -> Bool {
        return lhs.byte0 == rhs.byte0 &&
            lhs.byte1 == rhs.byte1 &&
            lhs.byte2 == rhs.byte2 &&
            lhs.byte3 == rhs.byte3 &&
            lhs.byte4 == rhs.byte4 &&
            lhs.byte5 == rhs.byte5 &&
            lhs.byte6 == rhs.byte6 &&
            lhs.byte7 == rhs.byte7 &&
            lhs.byte8 == rhs.byte8 &&
            lhs.byte9 == rhs.byte9 &&
            lhs.byte10 == rhs.byte10 &&
            lhs.byte11 == rhs.byte11
    }
    
    public func hash(into hasher: inout Hasher) {
        byte0.hash(into: &hasher)
        byte1.hash(into: &hasher)
        byte2.hash(into: &hasher)
        byte3.hash(into: &hasher)
        byte4.hash(into: &hasher)
        byte5.hash(into: &hasher)
        byte6.hash(into: &hasher)
        byte7.hash(into: &hasher)
        byte8.hash(into: &hasher)
        byte9.hash(into: &hasher)
        byte10.hash(into: &hasher)
        byte11.hash(into: &hasher)
    }
}

extension ObjectId: CustomStringConvertible {
    public var description: String {
        return self.hexString
    }
}

fileprivate let radix16table: [UInt8] = [0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x61, 0x62, 0x63, 0x64, 0x65, 0x66]
