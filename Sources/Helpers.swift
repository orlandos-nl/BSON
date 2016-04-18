//
//  String.swift
//  BSON
//
//  Created by Robbert Brandsma on 18-04-16.
//
//

import Foundation

public extension String {
    public var bsonData : [UInt8] {
        return Value.string(self).bsonData
    }
    
    public var cStringBsonData : [UInt8] {
        var byteArray = self.utf8.filter{$0 != 0x00}
        byteArray.append(0x00)
        
        return byteArray
    }
    
    /// Instantiate a string from BSON (UTF8) data, including the length of the string.
    public static func instantiate(bsonData data: [UInt8]) throws -> String {
        var 🖕 = 0
        
        return try instantiate(bsonData: data, consumedBytes: &🖕)
    }
    
    /// Instantiate a string from BSON (UTF8) data, including the length of the string.
    public static func instantiate(bsonData data: [UInt8], consumedBytes: inout Int) throws -> String {
        // Check for null-termination and at least 5 bytes (length spec + terminator)
        guard data.count >= 5 && data.last == 0x00 else {
            throw DeserializationError.InvalidLastElement
        }
        
        // Get the length
        let length = try Int32.instantiate(bsonData: Array(data[0...3]))
        
        // Check if the data is at least the right size
        guard data.count >= Int(length) + 4 else {
            throw DeserializationError.ParseError
        }
        
        // Empty string
        if length == 1 {
            consumedBytes = 5
            
            return ""
        }
        
        guard length > 0 else {
            throw DeserializationError.ParseError
        }
        
        var stringData = Array(data[4..<Int(length + 3)])
        
        guard let string = String(bytesNoCopy: &stringData, length: stringData.count, encoding: NSUTF8StringEncoding, freeWhenDone: false) else {
            throw DeserializationError.ParseError
        }
        
        consumedBytes = Int(length + 4)
        
        return string
    }
    
    /// Instantiate a String from a CString (a null terminated string of UTF8 characters, not containing null)
    public static func instantiateFromCString(bsonData data: [UInt8]) throws -> String {
        var 🖕 = 0
        
        return try instantiateFromCString(bsonData: data, consumedBytes: &🖕)
    }
    
    /// Instantiate a String from a CString (a null terminated string of UTF8 characters, not containing null)
    public static func instantiateFromCString(bsonData data: [UInt8], consumedBytes: inout Int) throws -> String {
        guard data.contains(0x00) else {
            throw DeserializationError.ParseError
        }
        
        guard let stringData = data.split(separator: 0x00, maxSplits: 1, omittingEmptySubsequences: false).first else {
            throw DeserializationError.ParseError
        }
        
        consumedBytes = stringData.count+1
        
        guard let string = String(bytes: stringData, encoding: NSUTF8StringEncoding) else {
            throw DeserializationError.ParseError
        }
        
        return string
    }
}

public extension Int16 {
    public var bsonData : [UInt8] {
        var integer = self
        return withUnsafePointer(&integer) {
            Array(UnsafeBufferPointer(start: UnsafePointer<UInt8>($0), count: sizeof(Int16)))
        }
    }
    
    internal static func instantiate(bsonData data: [UInt8]) throws -> Int16 {
        guard data.count >= 2 else {
            throw DeserializationError.InvalidElementSize
        }
        
        let integer = UnsafePointer<Int16>(data).pointee
        return integer
    }
}

public extension Int32 {
    public var bsonData : [UInt8] {
        return Value.int32(self).bsonData
    }
    
    /// Instantiate from 4 bytes of BSON
    public static func instantiate(bsonData data: [UInt8]) throws -> Int32 {
        guard data.count >= 4 else {
            throw DeserializationError.InvalidElementSize
        }
        
        let integer = UnsafePointer<Int32>(data).pointee
        return integer
    }
}

public extension Int64 {
    public var bsonData : [UInt8] {
        return Value.int64(self).bsonData
    }
    
    /// Restore given Int64 from storage
    public static func instantiate(bsonData data: [UInt8]) throws -> Int64 {
        guard data.count >= 8 else {
            throw DeserializationError.InvalidElementSize
        }
        
        let integer = UnsafePointer<Int64>(data).pointee
        return integer
    }
}

public extension Int {
    public var bsonData : [UInt8] {
        return Value.int64(Int64(self)).bsonData
    }
}