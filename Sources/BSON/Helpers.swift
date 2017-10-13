//
//  String.swift
//  BSON
//
//  Created by Robbert Brandsma on 18-04-16.
//
//

import Foundation

public typealias Byte = UInt8
public typealias Bytes = [UInt8]

internal extension String {
    /// The bytes in this `String`
    internal var bytes: Data {
        return self.makeBinary()
    }
    
    /// This `String` as c-string
    internal var cStringBytes: Data {
        var serialized = Data()
        serialized.reserveCapacity(self.utf8.count &+ 1)
        
        for character in self.utf8 where character != 0x00 {
            serialized.append(character)
        }
        
        serialized.append(0x00)
        
        return serialized
    }
    
    /// Instantiate a string from BSON (UTF8) data, including the length of the string.
    internal static func instantiate(data: Data, consumedBytes: inout Int) throws -> String {
        let res = try _instant(data: data)
        consumedBytes = res.0
        return res.1
    }
    
    internal static func _instant(data: Data) throws -> (Int, String) {
        // Check for null-termination and at least 5 bytes (length spec + terminator)
        guard data.count >= 5 && data.last == 0x00 else {
            throw DeserializationError.invalidLastElement
        }
        
        // Get the length
        let length = Int32(data[0...3])
        
        // Check if the data is at least the right size
        guard data.count >= Int(length) + 4 else {
            throw DeserializationError.invalidElementSize
        }
        
        // Empty string
        if length == 1 {
            return (5, "")
        }
        
        guard length > 0 else {
            throw DeserializationError.invalidElementSize
        }
        
        guard let string = String(data: data[4..<Int(length + 3)], encoding: .utf8) else {
            throw DeserializationError.unableToInstantiateString
        }
        
        return (Int(length + 4), string)
    }
    
    /// Instantiate a String from a CString (a null terminated string of UTF8 characters, not containing null)
    internal static func instantiateFromCString(bytes data: Bytes) throws -> String {
        var 🖕 = 0
        
        return try instantiateFromCString(bytes: data, consumedBytes: &🖕)
    }
    
    /// Instantiate a String from a CString (a null terminated string of UTF8 characters, not containing null)
    internal static func instantiateFromCString(bytes data: Bytes, consumedBytes: inout Int) throws -> String {
        let res = try _cInstant(bytes: data)
        consumedBytes = res.0
        return res.1
    }
    
    internal static func _cInstant(bytes data: Bytes) throws -> (Int, String) {
        guard data.contains(0x00) else {
            throw DeserializationError.missingNullTerminatorInString
        }
        
        guard let stringData = data.split(separator: 0x00, maxSplits: 1, omittingEmptySubsequences: false).first else {
            throw DeserializationError.noCStringFound
        }
        
        guard let string = String(bytes: stringData, encoding: String.Encoding.utf8) else {
            throw DeserializationError.unableToInstantiateString(fromBytes: Array(stringData))
        }
        
        return (stringData.count+1, string)
    }
}

internal protocol BSONBytesProtocol {}

internal protocol BSONMakeBytesProtocol: BSONBytesProtocol {
    func makeBytes() -> Bytes
}

extension Int : BSONBytesProtocol {
    internal func makeBytes() -> Data {
        let integer = self.littleEndian
        
        return Data([
            Byte(integer & 0xFF),
            Byte((integer >> 8) & 0xFF),
            Byte((integer >> 16) & 0xFF),
            Byte((integer >> 24) & 0xFF),
            Byte((integer >> 32) & 0xFF),
            Byte((integer >> 40) & 0xFF),
            Byte((integer >> 48) & 0xFF),
            Byte((integer >> 56) & 0xFF),
        ])
    }
}

extension Int32 : BSONBytesProtocol {
    internal func makeBytes() -> Data {
        let integer = self.littleEndian
        
        return Data([
            Byte(integer & 0xFF),
            Byte((integer >> 8) & 0xFF),
            Byte((integer >> 16) & 0xFF),
            Byte((integer >> 24) & 0xFF),
        ])
    }
    
    internal func makeBigEndianBytes() -> Data {
        let integer = self.bigEndian
        
        return Data([
            Byte(integer & 0xFF),
            Byte((integer >> 8) & 0xFF),
            Byte((integer >> 16) & 0xFF),
            Byte((integer >> 24) & 0xFF),
        ])
    }
}

extension Int16 : BSONBytesProtocol {
    internal func makeBytes() -> Data {
        let integer = self.littleEndian
        
        return Data([
            Byte((integer >> 8) & 0xFF),
            Byte(integer & 0xFF)
        ])
    }
}

extension Int8 : BSONBytesProtocol {
    internal func makeBytes() -> Bytes {
        return [Byte(self)]
    }
}

extension UInt : BSONBytesProtocol {
    internal func makeBytes() -> Data {
        let integer = self.littleEndian
        
        return Data([
            Byte(integer & 0xFF),
            Byte((integer >> 8) & 0xFF),
            Byte((integer >> 16) & 0xFF),
            Byte((integer >> 24) & 0xFF),
            Byte((integer >> 32) & 0xFF),
            Byte((integer >> 40) & 0xFF),
            Byte((integer >> 48) & 0xFF),
            Byte((integer >> 56) & 0xFF),
        ])
    }
}

extension UInt32 : BSONBytesProtocol {
    internal func makeBytes() -> Data {
        let integer = self.littleEndian
        
        return Data([
            Byte(integer & 0xFF),
            Byte((integer >> 8) & 0xFF),
            Byte((integer >> 16) & 0xFF),
            Byte((integer >> 24) & 0xFF),
        ])
    }
}

extension UInt16 : BSONBytesProtocol {
    internal func makeBytes() -> Data {
        let integer = self.littleEndian
        
        return Data([
            Byte(integer & 0xFF),
            Byte((integer >> 8) & 0xFF)
        ])
    }
}

extension Byte : BSONBytesProtocol {
    internal func makeBytes() -> Data {
        return Data([self])
    }
}

extension Double : BSONBytesProtocol {
    internal func makeBytes() -> Data {
        var integer = self
        return withUnsafePointer(to: &integer) {
            $0.withMemoryRebound(to: Byte.self, capacity: MemoryLayout<Double>.size) {
                Data(UnsafeBufferPointer(start: $0, count: MemoryLayout<Double>.size))
            }
        }
    }
}
