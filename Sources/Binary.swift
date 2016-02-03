//
//  Binary.swift
//  BSON
//
//  Created by Joannis Orlandos on 23/01/16.
//  Copyright © 2016 Robbert Brandsma. All rights reserved.
//

import Foundation

/// Used for storing arbitrary data in a BSON Document
public struct Binary : BSONElementConvertible {
    /// .Binary
    public var elementType: ElementType {
        return .Binary
    }

    /// Arbitrary data stored in this `Binary` instance.
    public var data: [UInt8]
    
    /// The BSON specification allows you to set a subType for every Binary. It says:
    /// ```
    /// subtype	::=	"\x00"	Generic binary subtype
    ///         |	"\x01"	Function
    ///         |	"\x02"	Binary (Old)
    ///         |	"\x03"	UUID (Old)
    ///         |	"\x04"	UUID
    ///         |	"\x05"	MD5
    ///         |	"\x80"	User defined
    /// ```
    public let subType: UInt8

    /// Returns the data in a format ready to be stored in a BSON Document.
    public var bsonData: [UInt8] {
        guard data.count < Int(Int32.max) else {
            return Int32(0).bsonData + [0]
        }

        let length = Int32(data.count)
        return length.bsonData + [subType] + data
    }

    /// The length of arbitrary data is .Undefined
    public static var bsonLength: BSONLength {
        return .Undefined
    }

    /// Create a new `Binary` instance with the given data, provided as an array of bytes ([UInt8])
    ///
    /// - param data: The data to store in this `Binary`
    /// - param subType: Optionally, a subtype for your data.
    public init(data: [UInt8], subType: UInt8 = 0) {
        self.data = data
        self.subType = subType
    }

    /// Creates a new `Binary` instance from a Foundation `NSData` object.
    ///
    /// - param data: The data to store in BSON as NSData
    /// - param subType: Optionally, a subtype for your data.
    public init(data: NSData, subType: UInt8 = 0) {
        self.data = [UInt8](count: data.length, repeatedValue: 0)
        data.getBytes(&self.data, length: self.data.count)
        self.subType = subType
    }

    /// Instantiate a new Binary instance from BSON
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

    /// Instantiate a new Binary instance from BSON
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
