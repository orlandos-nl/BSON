//
//  BSONTests.swift
//  BSONTests
//
//  Created by Robbert Brandsma on 23-01-16.
//  Copyright © 2016 Robbert Brandsma. All rights reserved.
//

import Foundation
import XCTest
@testable import BSON

#if os(Linux)
    import Glibc
#endif

final class BSONInternalTests: XCTestCase {
    static var allTests : [(String, (BSONInternalTests) -> () throws -> Void)] {
        return [
            ("testCStringSerialization", testCStringSerialization),
            ("testInt16", testInt16),
            ("testRegexInit", testRegexInit),
            // Other tests go here
        ]
    }
    
    func testCStringSerialization() {
        // This is "ABCD"
        let rawData: [UInt8] = [0x41, 0x42, 0x43, 0x44, 0x00]
        let result = "ABCD"
        
        let string = try! String.instantiateFromCString(bytes: rawData)
        XCTAssertEqual(string, result, "Instantiating a CString from BSON data works correctly")
        
        let generatedData = result.cStringBytes
        XCTAssertEqual(generatedData, rawData, "Converting a String to CString BSON data results in the correct data")
    }
    
    func testInt16() throws {
        let int16: Int16 = try fromBytes([0x01, 0x02])
        XCTAssert(int16 == 513)
        
        XCTAssertThrowsError(try fromBytes([0x01]) as Int16)
    }
    
    func testRegexInit() throws {
        let a = RegularExpression(pattern: "/([A-Z])\\w+/g", options: [])
        XCTAssert("/([A-Z])\\w+/g".cStringBytes + "".cStringBytes == a.makeBinary())
    }
}
