import Foundation

/// The 64-bit Double (0x01) BSON-type
extension Double : BSONElement {
    /// .Double
    public var elementType: ElementType {
        return .Double
    }

    /// Used internally
    public static func instantiate(bsonData data: [UInt8]) throws -> Double {
        var 🖕 = 0
        
        return try instantiate(bsonData: data, consumedBytes: &🖕, type: .Double)
    }
    
    /// Used internally
    public static func instantiate(bsonData data: [UInt8], inout consumedBytes: Int, type: ElementType) throws -> Double {
        guard data.count >= 8 else {
            throw DeserializationError.InvalidElementSize
        }
        
        let double = UnsafePointer<Double>(data).memory
        consumedBytes = 8
        return double
    }
    
    /// Used internally
    public var bsonData: [UInt8] {
        var double = self
        return withUnsafePointer(&double) {
            Array(UnsafeBufferPointer(start: UnsafePointer<UInt8>($0), count: sizeof(Double)))
        }
    }
    
    /// .Fixed(length: 8)
    public static let bsonLength = BSONLength.Fixed(length: 8)
}