//
// Created by joannis on 28-1-16.
//

import Foundation

public struct RegularExpression : BSONElementConvertible {
    let pattern: String
    let options: String
    let regex: NSRegularExpression

    init(pattern: String, options: String) throws {
        self.pattern = pattern
        self.options = options

        let optionList: NSRegularExpressionOptions = []

        // TODO: Use the options string

        regex = try NSRegularExpression(pattern: pattern, options: optionList)
    }

    public var elementType: ElementType {
        return .RegularExpression
    }

    /// Here, return the same data as you would accept in the initializer
    public var bsonData: [UInt8] {
        return pattern.cStringBsonData + options.cStringBsonData
    }

    public static var bsonLength: BsonLength {
        return .Undefined
    }

    /// The initializer expects the data for this element, starting AFTER the element type
    public static func instantiate(bsonData data: [UInt8], inout consumedBytes: Int) throws -> RegularExpression {
        consumedBytes = data.count
        return try self.instantiate(bsonData: data)
    }

    public static func instantiate(bsonData data: [UInt8]) throws -> RegularExpression {
        guard let stringTerminatorIndex = data.indexOf(0) else {
            throw DeserializationError.ParseError
        }

        let regex = try String.instantiate(bsonData: Array(data[0...stringTerminatorIndex - 1]))
        let options = try String.instantiate(bsonData: Array(data[stringTerminatorIndex...data.count]))

        return try RegularExpression(pattern: regex, options: options)
    }
}