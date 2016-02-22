//
//  ArrayDictionaryDocument.swift
//  BSON
//
//  Created by Joannis Orlandos on 01/02/16.
//  Copyright © 2016 Robbert Brandsma. All rights reserved.
//

import Foundation

/// The prefix * operator will be deprecated as soon as it isn't needed anymore.
/// The reason for adding the operator is that the Swift compiler sometimes likes to create `NSArray`s where it should be creating Swift `Array`s.
prefix operator * { }

/// Prefix * operator for Dictionaries
public prefix func *(input: [String : BSONElement]) -> Document {
    // 🖕, Swift!
    return Document(native: input)
}

/// Prefix * operator for arrays
public prefix func *(input: [BSONElement]) -> Document {
    // 🖕, Swift!
    return Document(native: input)
}
