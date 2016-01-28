//
//  Binary.swift
//  BSON
//
//  Created by Joannis Orlandos on 23/01/16.
//  Copyright © 2016 Robbert Brandsma. All rights reserved.
//

import Foundation

public struct Binary : BSONElementConvertible {
    public var elementType: ElementType {
        return .Binary
    }

    public var data: [UInt8]
    public let subType: UInt8
    
    public var bsonData: [UInt8] {
        let length = Int32(data.count)
        return length.bsonData + [subType] + data
    }
    
    public static var bsonLength: BsonLength {
        return .Undefined
    }
    
    public init(binaryData: [UInt8], subType: UInt8 = 0) {
        self.data = binaryData
        self.subType = subType
    }
    
    /// The initializer expects the data for this element, starting AFTER the element type
    public static func instantiate(bsonData data: [UInt8], inout consumedBytes: Int) throws -> Binary {
        consumedBytes = data.count
        return self.init(binaryData: data)
    }
    
    public static func instantiate(bsonData data: [UInt8]) throws -> Binary {
        return self.init(binaryData: data)
    }
}

extension NSData {
    public convenience init(_ binary: Binary) {
        var binary = binary
        self.init(bytes: &binary.data, length: binary.data.count)
    }
}