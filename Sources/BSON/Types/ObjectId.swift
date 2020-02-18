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
        let storage = UnsafeMutablePointer<UInt8>.allocate(capacity: 12)
        defer {
            storage.deallocate()
        }
        
        let cString = hex.utf8CString
        
        // 24 characters + 1 null terminator
        guard cString.count == 25 else {
            return nil
        }
        
        var input = 0
        var output = 0
        while input < 23 {
            guard
                let c1 = cString[input].hexDecoded(),
                let c2 = cString[input &+ 1].hexDecoded()
            else {
                return nil
            }
            
            storage[output] = UInt8(bitPattern: c1 << 4) | UInt8(bitPattern: c2)
            
            input = input &+ 2
            output = output &+ 1
        }
        
        _timestamp = storage.withMemoryRebound(to: UInt32.self, capacity: 1) { $0.pointee.bigEndian }
        _random = storage.advanced(by: 4).withMemoryRebound(to: UInt64.self, capacity: 1) { $0.pointee.bigEndian }
    }
    
    /// The 12 bytes represented as 24-character hex-string
    public var hexString: String {
        var data = Data()
        data.reserveCapacity(24)
        
        withUnsafeBytes(of: _timestamp.bigEndian) { buffer in
            let buffer = buffer.bindMemory(to: UInt8.self)
            
            data.appendHexCharacters(of: buffer[0])
            data.appendHexCharacters(of: buffer[1])
            data.appendHexCharacters(of: buffer[2])
            data.appendHexCharacters(of: buffer[3])
        }
        
        withUnsafeBytes(of: _random.bigEndian) { buffer in
            let buffer = buffer.bindMemory(to: UInt8.self)
            
            data.appendHexCharacters(of: buffer[0])
            data.appendHexCharacters(of: buffer[1])
            data.appendHexCharacters(of: buffer[2])
            data.appendHexCharacters(of: buffer[3])
            data.appendHexCharacters(of: buffer[4])
            data.appendHexCharacters(of: buffer[5])
            data.appendHexCharacters(of: buffer[6])
            data.appendHexCharacters(of: buffer[7])
        }
        
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

fileprivate extension Int8 {
    func hexDecoded() -> Int8? {
        let byte: Int8
        
        if self >= 0x61 {
            byte = self - 0x20
        } else {
            byte = self
        }
        
        switch byte {
        case 0x30: return 0b00000000
        case 0x31: return 0b00000001
        case 0x32: return 0b00000010
        case 0x33: return 0b00000011
        case 0x34: return 0b00000100
        case 0x35: return 0b00000101
        case 0x36: return 0b00000110
        case 0x37: return 0b00000111
        case 0x38: return 0b00001000
        case 0x39: return 0b00001001
        case 0x41: return 0b00001010
        case 0x42: return 0b00001011
        case 0x43: return 0b00001100
        case 0x44: return 0b00001101
        case 0x45: return 0b00001110
        case 0x46: return 0b00001111
        default: return nil
        }
    }
}

fileprivate extension Data {
    mutating func appendHexCharacters(of byte: UInt8) {
        append((byte >> 4).singleHexCharacter)
        append((byte & 0b00001111).singleHexCharacter)
    }
}

fileprivate extension UInt8 {
    var singleHexCharacter: UInt8 {
        switch self {
        case 0b00000000: return 0x30
        case 0b00000001: return 0x31
        case 0b00000010: return 0x32
        case 0b00000011: return 0x33
        case 0b00000100: return 0x34
        case 0b00000101: return 0x35
        case 0b00000110: return 0x36
        case 0b00000111: return 0x37
        case 0b00001000: return 0x38
        case 0b00001001: return 0x39
        case 0b00001010: return 0x61
        case 0b00001011: return 0x62
        case 0b00001100: return 0x63
        case 0b00001101: return 0x64
        case 0b00001110: return 0x65
        case 0b00001111: return 0x66
        default:
            fatalError("Invalid 4 bits provided")
        }
    }
}
