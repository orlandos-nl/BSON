extension String : BSONElementConvertible {
    public var elementType: ElementType {
        return .String
    }
    
    /// The initializer expects the data for this element, starting AFTER the element type
    public static func instantiate(var bsonData data: [UInt8]) throws -> String {
        guard data.count > 0 && data.removeLast() == 0x00 else {
            throw DeserializationError.InvalidLastElement
        }
        
        guard let instance = String(data: NSData(bytes: data, length: data.count), encoding: NSUTF8StringEncoding) else {
            throw DeserializationError.InvalidElementContents
        }
        
        return instance
    }
    
    /// Here, return the same data as you would accept in the initializer
    public var bsonData: [UInt8] {
        var byteArray = Array(utf8)
        byteArray.append(0x00)
        
        return byteArray
    }
}