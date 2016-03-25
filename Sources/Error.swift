//
//  Error.swift
//  BSON
//
//  Created by Robbert Brandsma on 23-01-16.
//  Copyright © 2016 Robbert Brandsma. All rights reserved.
//

import Foundation

/// All errors that can occur when (de)serializing BSON
public enum DeserializationError : ErrorProtocol {
    /// The Document doesn't have a valid length
    case InvalidDocumentLength
    
    /// The instantiating went wrong because the element has an invalid size
    case InvalidElementSize
    
    /// The contents of the BSON binary data was invalid
    case InvalidElementContents
    
    /// The BSON Element type was unknown
    case UnknownElementType
    
    /// The lsat element of the BSON Binary Array was invalid
    case InvalidLastElement
    
    /// Something went wrong with parsing (yeah.. very specific)
    case ParseError
    
    /// This operation was invalid
    case InvalidOperation
}