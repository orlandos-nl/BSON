import Foundation
import NIO

/// An error that occurs if the ObjectId was initialized with an invalid HexString
private struct InvalidObjectIdString: Error {
    var hex: String
}

public struct ObjectId {
    /// The internal Storage Buffer
    let _timestamp: UInt32
    let _random: UInt64
 
    public init() {
        self._timestamp = UInt32(Date().timeIntervalSince1970)
        self._random = .random(in: .min ... .max)
    }
    
    internal init(timestamp: UInt32, random: UInt64) {
        _timestamp = timestamp
        _random = random
    }
    
    public static func make(from hex: String) throws -> ObjectId {
        guard let me = self.init(hex) else {
            throw InvalidObjectIdString(hex: hex)
        }
        
        return me
    }

    /// Decodes the ObjectID from the provided (24 character) hexString
    public init?(_ hex: String) {
        guard hex.count == 24 else {
            return nil
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
            return nil
        }
        
        (_timestamp, _random) = storage.withUnsafeBytes { bytes in
            let address = bytes.baseAddress!
            
            let timestamp = address.assumingMemoryBound(to: UInt32.self).pointee.littleEndian
            let random = (address + 4).assumingMemoryBound(to: UInt64.self).pointee
            
            return (timestamp, random)
        }
    }
    
    /// The 12 bytes represented as 24-character hex-string
    public var hexString: String {
        var data = Data()
        data.reserveCapacity(24)
        
        func transform(_ byte: UInt8) {
            data.append(radix16table[Int(byte / 16)])
            data.append(radix16table[Int(byte % 16)])
        }
        
        let timestamp = _timestamp.bigEndian
        let random = _random.bigEndian
        
        // TODO: Take endianness into account
        transform(UInt8(truncatingIfNeeded: timestamp >> 24))
        transform(UInt8(truncatingIfNeeded: timestamp >> 16))
        transform(UInt8(truncatingIfNeeded: timestamp >> 8))
        transform(UInt8(truncatingIfNeeded: timestamp))
        
        transform(UInt8(truncatingIfNeeded: random >> 56))
        transform(UInt8(truncatingIfNeeded: random >> 48))
        transform(UInt8(truncatingIfNeeded: random >> 40))
        transform(UInt8(truncatingIfNeeded: random >> 32))
        transform(UInt8(truncatingIfNeeded: random >> 24))
        transform(UInt8(truncatingIfNeeded: random >> 16))
        transform(UInt8(truncatingIfNeeded: random >> 8))
        transform(UInt8(truncatingIfNeeded: random))
        
        return String(data: data, encoding: .utf8)!
    }
    
    /// The creation date of this ObjectId
    public var date: Date {
        return Date(timeIntervalSince1970: Double(_timestamp))
    }
}

extension ObjectId: Hashable, Comparable {
    public static func ==(lhs: ObjectId, rhs: ObjectId) -> Bool {
        return lhs._random == rhs._random && lhs._timestamp == rhs._timestamp 
    }
    
    public static func <(lhs: ObjectId, rhs: ObjectId) -> Bool {
        if lhs._timestamp == rhs._timestamp {
            return lhs._random == rhs._random
        }
        
        return lhs._timestamp < rhs._timestamp
    }
    
    public func hash(into hasher: inout Hasher) {
        _timestamp.hash(into: &hasher)
        _random.hash(into: &hasher)
    }
}

extension ObjectId: LosslessStringConvertible {
    public var description: String {
        return self.hexString
    }
}

fileprivate let radix16table: [UInt8] = [0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x61, 0x62, 0x63, 0x64, 0x65, 0x66]
