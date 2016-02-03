import Foundation

/// The UTF8 BSON String type (0x02)
extension String : BSONElementConvertible {
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
        
        var stringData = Array(data[4..<Int(length + 3)])
        
        guard let string = String(bytesNoCopy: &stringData, length: stringData.count, encoding: NSUTF8StringEncoding, freeWhenDone: false) else {
            throw DeserializationError.ParseError
        }
        
        consumedBytes = Int(length + 4)
        
        return string
    }

    publics static func instantiateFromCString(bsonData data: [UInt8]) throws -> String {
        var 🖕 = 0
        
        return try instantiateFromCString(bsonData: data, consumedBytes: &🖕)
    }
    
    public static func instantiateFromCString(bsonData data: [UInt8], inout consumedBytes: Int) throws -> String {
        guard let stringData = data.split(0x00, maxSplit: 1, allowEmptySlices: true).first else {
            throw DeserializationError.ParseError
        }
        
        consumedBytes = stringData.count+1
        
        guard let string = String(bytes: stringData, encoding: NSUTF8StringEncoding) else {
            throw DeserializationError.ParseError
        }
        
        return string
    }
    
    /// Here, return the same data as you would accept in the initializer
    public var bsonData: [UInt8] {
        var byteArray = Int32(utf8.count + 1).bsonData
        byteArray.appendContentsOf(utf8)
        byteArray.append(0x00)
        
        return byteArray
    }
    
    public var cStringBsonData: [UInt8] {
        var byteArray = Array(self.stringByReplacingOccurrencesOfString("\0", withString: "").utf8)
        byteArray.append(0x00)
        
        return byteArray
    }
    
    /// The length of a String is .Undefined
    public static let bsonLength = BSONLength.Undefined
}