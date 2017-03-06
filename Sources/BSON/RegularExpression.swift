//
//  RegularExpression.swift
//  BSON
//
//  Created by Robbert Brandsma on 13-02-17.
//
//

import Foundation

/// The `RegularExpression` struct represents a regular expression as part of a BSON `Document`.
///
/// An extension to `NSRegularExpression` is provided for converting between `Foundation.NSRegularExpression` and `BSON.RegularExpression`.
public struct RegularExpression {
    public var pattern: String
    public var options: NSRegularExpression.Options
    
    /// Returns an initialized BSON RegularExpression instance with the specified regular expression pattern and options.
    public init(pattern: String, options: NSRegularExpression.Options = []) {
        self.pattern = pattern
        self.options = options
    }
    
    /// Initializes the `RegularExpression` using the pattern and options from the given NSRegularExpression.
    public init(_ regex: NSRegularExpression) {
        self.pattern = regex.pattern
        self.options = regex.options
    }
}

public extension NSRegularExpression {
    /// Returns an initialized NSRegularExpression instance with the pattern and options from the specified BSON regular expression.
    public convenience init(_ regex: RegularExpression) throws {
        try self.init(pattern: regex.pattern, options: regex.options)
    }
}
