//
//  Error.swift
//  BSON
//
//  Created by Robbert Brandsma on 23-01-16.
//  Copyright © 2016 Robbert Brandsma. All rights reserved.
//

/// All errors that can occur when (de)serializing BSON
public enum DeserializationError : Error {
    /// The Document doesn't have a valid length
    case invalidDocumentLength
    
    /// The instantiating went wrong because the element has an invalid size
    case invalidElementSize
    
    /// The contents of the BSON binary data was invalid
    case invalidElementContents
    
    /// The BSON Element type was unknown
    case unknownElementType
    
    /// The lsat element of the BSON Binary Array was invalid
    case invalidLastElement
    
    /// The given length for the ObjectId isn't 12-bytes or a 24-character hexstring
    case InvalidObjectIdLength
    
    /// String with given bytes couldn't be instantiated
    case unableToInstantiateString(fromBytes: Bytes)
    
    /// -
    case missingNullTerminatorInString
    
    /// No CString found in given data
    case noCStringFound
}
