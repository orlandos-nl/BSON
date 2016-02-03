//
//  Binary.swift
//  BSON
//
//  Created by Joannis Orlandos on 23/01/16.
//  Copyright © 2016 Robbert Brandsma. All rights reserved.
//

import Foundation

/// Used for storing arbitrary data
public struct Binary : BSONElementConvertible {
    public var elementType: ElementType {
        return .Binary
    }

    public var data: [UInt8]
    public let subType: UInt8

    public var bsonData: [UInt8] {
        guard data.count < Int(Int32.max) else {
            return Int32(0).bsonData + [0]
        }

        let length = Int32(data.count)
        return length.bsonData + [subType] + data
    }

    public static var bsonLength: BsonLength {
        return .Undefined
    }

    /// Create a new `Binary` instance with the given data
    ///
    /// - param data: The data to store in this `Binary`
    /// - param subType: The BSON spec
    public init(data: [UInt8], subType: UInt8 = 0) {
        self.data = data
        self.subType = subType
    }

    public init(data: NSData, subType: UInt8 = 0) {
        self.data = [UInt8](count: data.length, repeatedValue: 0)
        data.getBytes(&self.data, length: self.data.count)
        self.subType = subType
    }

    public static func instantiate(bsonData data: [UInt8], inout consumedBytes: Int, type: ElementType) throws -> Binary {
        guard data.count >= 5 else {
            throw DeserializationError.InvalidElementSize
        }

        // TODO: This looks like the performance could be improved.
        let length = try Int32.instantiate(bsonData: Array(data[0...3]))
        let subType = data[4]

        guard data.count >= Int(length) + 5 else {
            throw DeserializationError.InvalidElementSize
        }

        let realData = length > 0 ? Array(data[5...Int(4+length)]) : []
        // length + subType + data
        consumedBytes = 4 + 1 + Int(length)

        return self.init(data: realData, subType: subType)
    }

    public static func instantiate(bsonData data: [UInt8]) throws -> Binary {
        var 🖕 = 0
        return try instantiate(bsonData: data, consumedBytes: &🖕, type: .Binary)
    }
}

extension NSData {
    /// Initialize the NSData object with a BSON binary
    public convenience init(_ binary: Binary) {
        var binary = binary
        self.init(bytes: &binary.data, length: binary.data.count)
    }
}
