//
//  ObjectID.swift
//  BSON
//
//  Created by Joannis Orlandos on 23/01/16.
//  Copyright © 2016 Robbert Brandsma. All rights reserved.
//

import Foundation

public struct ObjectID {
    
    public private(set) var data: [UInt8]
    
    public init(hexString: String) throws {
        data = hexString.characters.map { UInt8(String($0), radix: 16) }.flatMap{$0}
        
        guard data.count == 12 else {
            throw DeserializationError.ParseError
        }
    }
    
    public var hexString: String {
        return data.map{String($0, radix: 16, uppercase: false)}.joinWithSeparator("")
    }
}