//
//  String.swift
//  BSON
//
//  Created by Robbert Brandsma on 18-04-16.
//
//

import Foundation

internal extension String {
    /// The bytes in this `String`
    internal var bytes : [UInt8] {
        return self.makeBSONBinary()
    }
    
    /// This `String` as c-string
    internal var cStringBytes : [UInt8] {
        var byteArray = self.utf8.filter{$0 != 0x00}
        byteArray.append(0x00)
        
        return byteArray
    }
    
    /// Instantiate a string from BSON (UTF8) data, including the length of the string.
    internal static func instantiate(bytes data: [UInt8]) throws -> String {
        var 🖕 = 0
        
        return try instantiate(bytes: data, consumedBytes: &🖕)
    }
    
    /// Instantiate a string from BSON (UTF8) data, including the length of the string.
    internal static func instantiate(bytes data: [UInt8], consumedBytes: inout Int) throws -> String {
        let res = try _instant(bytes: data)
        consumedBytes = res.0
        return res.1
    }
    
    internal static func _instant(bytes data: [UInt8]) throws -> (Int, String) {
        // Check for null-termination and at least 5 bytes (length spec + terminator)
        guard data.count >= 5 && data.last == 0x00 else {
            throw DeserializationError.invalidLastElement
        }
        
        // Get the length
        let length = data[0...3].makeInt32()
        
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
        
        var stringData = Array(data[4..<Int(length + 3)])
        
        guard let string = String(bytesNoCopy: &stringData, length: stringData.count, encoding: String.Encoding.utf8, freeWhenDone: false) else {
            throw DeserializationError.unableToInstantiateString(fromBytes: stringData)
        }
        
        return (Int(length + 4), string)
    }
    
    /// Instantiate a String from a CString (a null terminated string of UTF8 characters, not containing null)
    internal static func instantiateFromCString(bytes data: [UInt8]) throws -> String {
        var 🖕 = 0
        
        return try instantiateFromCString(bytes: data, consumedBytes: &🖕)
    }
    
    /// Instantiate a String from a CString (a null terminated string of UTF8 characters, not containing null)
    internal static func instantiateFromCString(bytes data: [UInt8], consumedBytes: inout Int) throws -> String {
        let res = try _cInstant(bytes: data)
        consumedBytes = res.0
        return res.1
    }
    
    internal static func _cInstant(bytes data: [UInt8]) throws -> (Int, String) {
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
    func makeBytes() -> [UInt8]
}

extension Int : BSONBytesProtocol {
    internal func makeBytes() -> [UInt8] {
        var integer = self.littleEndian
        return withUnsafePointer(to: &integer) {
            $0.withMemoryRebound(to: UInt8.self, capacity: MemoryLayout<Int>.size) {
                Array(UnsafeBufferPointer(start: $0, count: MemoryLayout<Int>.size))
            }
        }
    }
}

extension Int64 : BSONBytesProtocol {
    internal func makeBytes() -> [UInt8] {
        let integer = self.littleEndian
        
        return [
            UInt8(integer & 0xFF),
            UInt8((integer >> 8) & 0xFF),
            UInt8((integer >> 16) & 0xFF),
            UInt8((integer >> 24) & 0xFF),
            UInt8((integer >> 32) & 0xFF),
            UInt8((integer >> 40) & 0xFF),
            UInt8((integer >> 48) & 0xFF),
            UInt8((integer >> 56) & 0xFF),
        ]
    }
}

extension Int32 : BSONBytesProtocol {
    internal func makeBytes() -> [UInt8] {
        let integer = self.littleEndian
        
        return [
            UInt8(integer & 0xFF),
            UInt8((integer >> 8) & 0xFF),
            UInt8((integer >> 16) & 0xFF),
            UInt8((integer >> 24) & 0xFF),
        ]
    }
    
    internal func makeBigEndianBytes() -> [UInt8] {
        let integer = self.bigEndian
        
        return [
            UInt8(integer & 0xFF),
            UInt8((integer >> 8) & 0xFF),
            UInt8((integer >> 16) & 0xFF),
            UInt8((integer >> 24) & 0xFF),
        ]
    }
}

extension Int16 : BSONBytesProtocol {
    internal func makeBytes() -> [UInt8] {
        let integer = self.littleEndian
        
        return [
            UInt8((integer >> 8) & 0xFF),
            UInt8(integer & 0xFF)
        ]
    }
}

extension Int8 : BSONBytesProtocol {
    internal func makeBytes() -> [UInt8] {
        return [UInt8(self)]
    }
}

extension UInt : BSONBytesProtocol {
    internal func makeBytes() -> [UInt8] {
        var integer = self.littleEndian
        return withUnsafePointer(to: &integer) {
            $0.withMemoryRebound(to: UInt8.self, capacity: MemoryLayout<UInt>.size) {
                Array(UnsafeBufferPointer(start: $0, count: MemoryLayout<UInt>.size))
            }
        }
    }
}

extension UInt64 : BSONBytesProtocol {
    internal func makeBytes() -> [UInt8] {
        let integer = self.littleEndian
        
        return [
            UInt8(integer & 0xFF),
            UInt8((integer >> 8) & 0xFF),
            UInt8((integer >> 16) & 0xFF),
            UInt8((integer >> 24) & 0xFF),
            UInt8((integer >> 32) & 0xFF),
            UInt8((integer >> 40) & 0xFF),
            UInt8((integer >> 48) & 0xFF),
            UInt8((integer >> 56) & 0xFF),
        ]
    }
}

extension UInt32 : BSONBytesProtocol {
    internal func makeBytes() -> [UInt8] {
        let integer = self.littleEndian
        
        return [
            UInt8(integer & 0xFF),
            UInt8((integer >> 8) & 0xFF),
            UInt8((integer >> 16) & 0xFF),
            UInt8((integer >> 24) & 0xFF),
        ]
    }
}

extension UInt16 : BSONBytesProtocol {
    internal func makeBytes() -> [UInt8] {
        let integer = self.littleEndian
        
        return [
            UInt8(integer & 0xFF),
            UInt8((integer >> 8) & 0xFF)
        ]
    }
}

extension UInt8 : BSONBytesProtocol {
    internal func makeBytes() -> [UInt8] {
        return [self]
    }
}

extension Double : BSONBytesProtocol {
    internal func makeBytes() -> [UInt8] {
        var integer = self
        return withUnsafePointer(to: &integer) {
            $0.withMemoryRebound(to: UInt8.self, capacity: MemoryLayout<Double>.size) {
                Array(UnsafeBufferPointer(start: $0, count: MemoryLayout<Double>.size))
            }
        }
    }
}
