import Foundation

extension String : BSONElementConvertible {
    public var elementType: ElementType {
        return .String
    }
    
    public static func instantiate(bsonData data: [UInt8]) throws -> String {
        var ditched = 0
        
        return try instantiate(bsonData: data, consumedBytes: &ditched)
    }
    
    /// The initializer expects the data for this element, starting AFTER the element type
    public static func instantiate(bsonData data: [UInt8], inout consumedBytes: Int) throws -> String {
        // Check for null-termination and at least 5 bytes (length spec + terminator)
        guard data.count >= 5 && data.last == 0x00 else {
            throw DeserializationError.InvalidLastElement
        }
        
        // Get the length
        var ditched = 0
        
        let length = try Int32.instantiate(bsonData: Array(data[0...3]), consumedBytes: &ditched)
        
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

    internal static func instantiateFromCString(bsonData data: [UInt8]) throws -> String {
        var ditched = 0
        
        return try instantiateFromCString(bsonData: data, bytesConsumed: &ditched)
    }
    
    internal static func instantiateFromCString(bsonData data: [UInt8], inout bytesConsumed: Int) throws -> String {
        bytesConsumed = data.count
        
        guard let string = String(bytes: data, encoding: NSUTF8StringEncoding) else {
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
        var byteArray = Array(utf8)
        byteArray.append(0x00)
        
        return byteArray
    }
    
    public static let bsonLength = BsonLength.NullTerminated
}