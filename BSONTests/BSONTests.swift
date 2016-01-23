//
//  BSONTests.swift
//  BSONTests
//
//  Created by Robbert Brandsma on 23-01-16.
//  Copyright © 2016 Robbert Brandsma. All rights reserved.
//

import XCTest
@testable import BSON

class BSONTests: XCTestCase {
    
    func testDoubleSerialization() {
        // This is 5.05
        let rawData: [UInt8] = [0x33, 0x33, 0x33, 0x33, 0x33, 0x33, 0x14, 0x40]
        let double = try! Double.instantiate(bsonData: rawData)
        XCTAssertEqual(double, 5.05, "Instantiating a Double from BSON data works correctly")
        
        let generatedData = 5.05.bsonData
        XCTAssert(generatedData == rawData, "Converting a Double to BSON data results in the correct data")
    }
    
    func testStringSerialization() {
        // This is "ABCD"
        let rawData: [UInt8] = [0x41, 0x42, 0x43, 0x44, 0x00]
        let double = try! String.instantiate(bsonData: rawData)
        XCTAssertEqual(double, "ABCD", "Instantiating a String from BSON data works correctly")
        
        let generatedData = "ABCD".bsonData
        XCTAssert(generatedData == rawData, "Converting a String to BSON data results in the correct data")
    }
    
}
