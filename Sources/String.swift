import Foundation

/// The UTF8 BSON String type (0x02)
extension String : BSONElement {
    /// .String
    public var elementType: ElementType {
        return .String
    }
    
    /// Instantiate a string from BSON (UTF8) data, including the length of the string.
    public static func instantiate(bsonData data: [UInt8]) throws -> String {
        var 🖕 = 0
        
        return try instantiate(bsonData: data, consumedBytes: &🖕, type: .String)
    }
    
    /// Instantiate a string from BSON (UTF8) data, including the length of the string.
    public static func instantiate(bsonData data: [UInt8], inout consumedBytes: Int, type: ElementType) throws -> String {
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
    public static func instantiateFromCString(bsonData data: [UInt8], inout consumedBytes: Int) throws -> String {
        guard data.contains(0x00) else {
            throw DeserializationError.ParseError
        }
        
        guard let stringData = data.split(0x00, maxSplit: 1, allowEmptySlices: true).first else {
            throw DeserializationError.ParseError
        }
        
        consumedBytes = stringData.count+1
        
        guard let string = String(bytes: stringData, encoding: NSUTF8StringEncoding) else {
            throw DeserializationError.ParseError
        }
        
        return string
    }
    
    /// The BSON data for this String, including the string length.
    public var bsonData: [UInt8] {
        var byteArray = Int32(utf8.count + 1).bsonData
        byteArray.appendContentsOf(utf8)
        byteArray.append(0x00)
        
        return byteArray
    }
    
    /// A null-terminated UTF8 version of the data of this String. Not containing length properties. If the string contains null characters, those are removed.
    public var cStringBsonData: [UInt8] {
        var byteArray = self.utf8.filter{$0 != 0x00}
        byteArray.append(0x00)
        
        return byteArray
    }
    
    /// The length of a String is .Undefined
    public static let bsonLength = BSONLength.Undefined
}