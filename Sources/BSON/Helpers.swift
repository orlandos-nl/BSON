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
    internal var bytes : Bytes {
        return self.makeBinary()
    }
    
    /// This `String` as c-string
    internal var cStringBytes : Bytes {
        var byteArray = self.utf8.filter{$0 != 0x00}
        byteArray.append(0x00)
        
        return byteArray
    }
    
    /// Instantiate a string from BSON (UTF8) data, including the length of the string.
    internal static func instantiate(bytes data: Bytes) throws -> String {
        var 🖕 = 0
        
        return try instantiate(bytes: data, consumedBytes: &🖕)
    }
    
    /// Instantiate a string from BSON (UTF8) data, including the length of the string.
    internal static func instantiate(bytes data: Bytes, consumedBytes: inout Int) throws -> String {
        let res = try _instant(bytes: data)
        consumedBytes = res.0
        return res.1
    }
    
    internal static func _instant(bytes data: Bytes) throws -> (Int, String) {
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
        
        let stringData = Array(data[4..<Int(length + 3)])
        
        guard let string = String(bytes: stringData, encoding: .utf8) else {
            throw DeserializationError.unableToInstantiateString(fromBytes: stringData)
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
    internal func makeBytes() -> Bytes {
        #if arch(s390x)
            let integer = self.bigEndian
        #else
            let integer = self.littleEndian
        #endif
        
        return [
            Byte(integer & 0xFF),
            Byte((integer >> 8) & 0xFF),
            Byte((integer >> 16) & 0xFF),
            Byte((integer >> 24) & 0xFF),
            Byte((integer >> 32) & 0xFF),
            Byte((integer >> 40) & 0xFF),
            Byte((integer >> 48) & 0xFF),
            Byte((integer >> 56) & 0xFF),
        ]
    }
}

extension Int32 : BSONBytesProtocol {
    internal func makeBytes() -> Bytes {
        #if arch(s390x)
            let integer = self.bigEndian
        #else
            let integer = self.littleEndian
        #endif

        return [
            Byte(integer & 0xFF),
            Byte((integer >> 8) & 0xFF),
            Byte((integer >> 16) & 0xFF),
            Byte((integer >> 24) & 0xFF),
        ]
    }
    
    internal func makeBigEndianBytes() -> Bytes {
        let integer = self.bigEndian
        
        return [
            Byte(integer & 0xFF),
            Byte((integer >> 8) & 0xFF),
            Byte((integer >> 16) & 0xFF),
            Byte((integer >> 24) & 0xFF),
        ]
    }
}

extension Int16 : BSONBytesProtocol {
    internal func makeBytes() -> Bytes {
        #if arch(s390x)
            let integer = self.bigEndian
        #else
            let integer = self.littleEndian
        #endif
        
        return [
            Byte((integer >> 8) & 0xFF),
            Byte(integer & 0xFF)
        ]
    }
}

extension Int8 : BSONBytesProtocol {
    internal func makeBytes() -> Bytes {
        return [Byte(self)]
    }
}

extension UInt : BSONBytesProtocol {
    internal func makeBytes() -> Bytes {
        #if arch(s390x)
            let integer = self.bigEndian
        #else
            let integer = self.littleEndian
        #endif

        return [
            Byte(integer & 0xFF),
            Byte((integer >> 8) & 0xFF),
            Byte((integer >> 16) & 0xFF),
            Byte((integer >> 24) & 0xFF),
            Byte((integer >> 32) & 0xFF),
            Byte((integer >> 40) & 0xFF),
            Byte((integer >> 48) & 0xFF),
            Byte((integer >> 56) & 0xFF),
        ]
    }
}

extension UInt32 : BSONBytesProtocol {
    internal func makeBytes() -> Bytes {
        #if arch(s390x)
            let integer = self.bigEndian
        #else
            let integer = self.littleEndian
        #endif

        return [
            Byte(integer & 0xFF),
            Byte((integer >> 8) & 0xFF),
            Byte((integer >> 16) & 0xFF),
            Byte((integer >> 24) & 0xFF),
        ]
    }
}

extension UInt16 : BSONBytesProtocol {
    internal func makeBytes() -> Bytes {
        #if arch(s390x)
            let integer = self.bigEndian
        #else
            let integer = self.littleEndian
        #endif

        return [
            Byte(integer & 0xFF),
            Byte((integer >> 8) & 0xFF)
        ]
    }
}

extension Byte : BSONBytesProtocol {
    internal func makeBytes() -> Bytes {
        return [self]
    }
}

extension Double : BSONBytesProtocol {
    internal func makeBytes() -> Bytes {
        var integer = self
        #if arch(s390x)
            return withUnsafePointer(to: &integer) {
                $0.withMemoryRebound(to: Byte.self, capacity: MemoryLayout<Double>.size) {
                    Array(UnsafeBufferPointer(start: $0, count: MemoryLayout<Double>.size))
                }
            }.reversed()
        #else
            return withUnsafePointer(to: &integer) {
                $0.withMemoryRebound(to: Byte.self, capacity: MemoryLayout<Double>.size) {
                    Array(UnsafeBufferPointer(start: $0, count: MemoryLayout<Double>.size))
                }
            }
        #endif
    }
}
