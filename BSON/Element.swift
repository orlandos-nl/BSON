//
//  Element.swift
//  BSON
//
//  Created by Robbert Brandsma on 23-01-16.
//  Copyright © 2016 Robbert Brandsma. All rights reserved.
//

import Foundation

internal enum ElementType : UInt8 {
    case Double = 0x01
    case String = 0x02
    case Document = 0x03
    case Array = 0x04
    case Binary = 0x05
    //  case DeprecatedUndefinedValue = 0x06
    case ObjectId = 0x07
    case Boolean = 0x08
    case DateTime = 0x09
    case NullValue = 0x0A
    case RegularExpression = 0x0B
    //  case DeprecatedDBPointer = 0x0C
    case JavaScriptCode = 0x0D
    //  case Deprecated = 0x0E
    case JavascriptCodeWithScope = 0x0F
    case Int32 = 0x10
    case Timestamp = 0x11
    case Int64 = 0x12
    case MinKey = 0xFF
    case MaxKey = 0x7F
}
