extension Double : BSONElementConvertible {
    public var elementType: ElementType {
        return .Double
    }
    
    public static func instantiate(bsonData data: [UInt8]) throws -> Double {
        guard data.count == 8 else {
            throw DeserializationError.InvalidElementSize
        }
        
        let double = UnsafePointer<Double>(data).memory
        return double
    }
    
    public var bsonData: [UInt8] {
        var double = self
        return withUnsafePointer(&double) {
            Array(UnsafeBufferPointer(start: UnsafePointer<UInt8>($0), count: sizeof(Double)))
        }
    }
}