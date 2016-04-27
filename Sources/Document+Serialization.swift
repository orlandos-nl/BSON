//
//  Document+BSONElement.swift
//  BSON
//
//  Created by Robbert Brandsma on 03-02-16.
//  Copyright © 2016 Robbert Brandsma. All rights reserved.
//

import Foundation

extension Document {
    /// Serialize the document, ready to store as a BSON file or sending over the network.
    /// You may concatenate output of this method into one long array, and instantiate that using
    /// `instantiateMultiple(...)`
    public var bsonData: [UInt8] {
        var body = [UInt8]()
        var length = 4
        
        elementLoop: for (key, element) in elements {
            if case .nothing = element {
                print("WARNING: Nothing in BSON Document")
                continue elementLoop
            }
            
            body += [element.typeIdentifier]
            body += key.cStringBsonData
            body += element.bsonData
        }
        
        body += [0x00]
        length += body.count
        
        let finalData = Int32(length).bsonData + body
        
        return finalData
    }
    
    public func write(toFile path: String) throws {
        var myData = self.bsonData
        let nsData = NSData(bytes: &myData, length: myData.count)
        
        try nsData.write(toFile: path)
    }
}
