//
//  RegularExpression.swift
//  BSON
//
//  Created by Robbert Brandsma on 23/07/2018.
//

import Foundation

/// The `RegularExpression` struct represents a regular expression as part of a BSON `Document`.
///
/// An extension to `NSRegularExpression` is provided for converting between `Foundation.NSRegularExpression` and `BSON.RegularExpression`.
public struct RegularExpression: Primitive, Hashable {
    private enum CodingKeys: String, CodingKey {
        case pattern = "$regex"
        case options = "$options"
    }
    
    public var pattern: String
    public var options: String
    
    /// Returns an initialized BSON RegularExpression instance with the specified regular expression pattern and options.
    public init(pattern: String, options: String) {
        self.pattern = pattern
        self.options = options
    }
    
    /// Initializes the `RegularExpression` using the pattern and options from the given NSRegularExpression.
    ///
    /// The following mapping is used for regular expression options (Foundation -> BSON):
    ///
    /// - caseInsensitive -> i
    /// - anchorsMatchLines -> m
    /// - dotMatchesLineSeparators -> s
    ///
    /// Other options are discarded.
    public init(_ regex: NSRegularExpression) {
        self.pattern = regex.pattern
        self.options = makeBSONOptions(from: regex.options)
    }
    
    // MARK: - Codable
    
    public init(from decoder: Decoder) throws {
        if let container = (try? decoder.singleValueContainer() as? AnySingleValueBSONDecodingContainer) ?? nil {
            self = try container.decodeRegularExpression()
        } else {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.pattern = try container.decode(String.self, forKey: .pattern)
            self.options = try container.decode(String.self, forKey: .options)
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(pattern, forKey: .pattern)
        try container.encode(options, forKey: .options)
    }
}

extension NSRegularExpression {
    /// Returns an initialized NSRegularExpression instance with the pattern and options from the specified BSON regular expression.
    public convenience init(_ regex: RegularExpression) throws {
        try self.init(pattern: regex.pattern, options: makeFoundationOptions(from: regex.options))
    }
}

extension NSRegularExpression: PrimitiveConvertible {
    public func makePrimitive() -> Primitive? {
        return RegularExpression(self)
    }
}

fileprivate func makeBSONOptions(from options: NSRegularExpression.Options) -> String {
    var optionsString = ""
    
    // Options are identified by characters, which must be stored in alphabetical order
    if options.contains(.caseInsensitive) {
        optionsString += "i"
    }
    
    if options.contains(.anchorsMatchLines) {
        optionsString += "m"
    }
    
    if options.contains(.dotMatchesLineSeparators) {
        optionsString += "s"
    }
    
    return optionsString
}

fileprivate func makeFoundationOptions(from string: String) -> NSRegularExpression.Options {
    var options: NSRegularExpression.Options = []
    
    if string.contains("i") {
        options.insert(.caseInsensitive)
    }
    
    if string.contains("m") {
        options.insert(.anchorsMatchLines)
    }
    
    if string.contains("s") {
        options.insert(.dotMatchesLineSeparators)
    }
    
    return options
}
