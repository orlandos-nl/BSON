//
// Created by joannis on 28-1-16.
//

import Foundation

/// A BSON representation for a regular expression
public struct RegularExpression {
    /// The regular expression pattern (a string)
    public var pattern: String
    
    /// The regular expression options string. No processing is done on this, however the BSON spec provides for storing this.
    public var options: String
    
    /// Create a new BSON regular expression
    init(pattern: String, options: String) {
        self.pattern = pattern
        self.options = options
    }
}

extension RegularExpression : BSONElement {
    /// .RegularExpression
    public var elementType: ElementType {
        return .RegularExpression
    }
    
    /// Convert this RegularExpression to BSON data
    public var bsonData: [UInt8] {
        return pattern.cStringBsonData + options.cStringBsonData
    }
    
    /// The length of a RegularExpression is not predetermined, thus .Undefined
    public static var bsonLength: BSONLength {
        // TODO: DoubleNullTerminated??
        return .Undefined
    }
    
    /// Instantiate a regular expression from raw data
    public static func instantiate(bsonData data: [UInt8]) throws -> RegularExpression {
        var 🖕 = 0
        return try instantiate(bsonData: data, consumedBytes: &🖕, type: .RegularExpression)
    }
    
    /// Instantiate a regular expression from raw data
    public static func instantiate(bsonData data: [UInt8], inout consumedBytes: Int, type: ElementType) throws -> RegularExpression {
        let k = data.split(0, maxSplit: 2, allowEmptySlices: true)
        guard k.count >= 2 else {
            throw DeserializationError.InvalidElementSize
        }
        
        let patternData = Array(k[0])
        let pattern = try String.instantiateFromCString(bsonData: patternData + [0x00])
        
        let optionsData = Array(k[1])
        let options = try String.instantiateFromCString(bsonData: optionsData + [0x00])
        
        // +1 for the null which is removed by the split
        consumedBytes = patternData.count+1 + optionsData.count+1
        
        return self.init(pattern: pattern, options: options)
    }
}
