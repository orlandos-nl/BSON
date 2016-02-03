//
//  BSONTests.swift
//  BSONTests
//
//  Created by Robbert Brandsma on 23-01-16.
//  Copyright © 2016 Robbert Brandsma. All rights reserved.
//

import Foundation
import XCTest
import BSON

class BSONPublicTests: XCTestCase {
    
    func testBasics() {
        let document: Document = [
            "hello": "I am a document created trough the public API",
            "subdocument": *["hello", "mother of god"]
        ]
        
        XCTAssert(document.count == 2)
    }
    
    func testBinarySerialization() {
        let data: [UInt8] = [0x01, 0x02, 0x03, 0x06, 0x0c, 0x18, 0x30, 0x60]
        
        // Instantiating with 8 bytes of data and converting to BSON data
        let binary = Binary(data: data)
        XCTAssert(binary.data == data)
        XCTAssert(binary.bsonData == ([8, 0, 0, 0, 0] as [UInt8] + data))
        
        // Try instantiating with a subtype
        let otherBinary = Binary(data: data, subType: 0x90)
        XCTAssert(otherBinary.data == data)
        XCTAssert(otherBinary.bsonData == ([8, 0, 0, 0, 144] as [UInt8] + data))
        
        // Instantiating from BSON data with a subtype
        let thirdBinary = try! Binary.instantiate(bsonData: Int32(8).bsonData + [5] + data)
        let fourthBinary = Binary(data: data, subType: 5)
        XCTAssert(thirdBinary.data == fourthBinary.data)
        
        // Instantiating with 0 bytes
        let fifthBinary = Binary(data: [])
        XCTAssert(fifthBinary.bsonData == Int32(0).bsonData + [0])
        
        // Instantiating from 0 BSON data bytes
        let sixthBinary = try! Binary.instantiate(bsonData: fifthBinary.bsonData)
        XCTAssert(sixthBinary.data.count == 0)
        
        // Instantiating with invalid BSON data
        do {
            let _ = try Binary.instantiate(bsonData: [0x34, 0x12, 0x2])
            XCTFail()
        } catch DeserializationError.InvalidElementSize {
            XCTAssert(true)
        } catch {
            XCTFail()
        }
        
        // Instantiating with more invalid BSON data
        do {
            let _ = try Binary.instantiate(bsonData: Int32(400).bsonData + [5] + [0x12, 0x25, 0x12])
            XCTFail()
        } catch DeserializationError.InvalidElementSize {
            XCTAssert(true)
        } catch {
            XCTFail()
        }
        
        // One more: Instantiating with more invalid BSON data
        do {
            let _ = try Binary.instantiate(bsonData: Int32(4).bsonData + [5] + [0x12, 0x25, 0x12])
            XCTFail()
        } catch DeserializationError.InvalidElementSize {
            XCTAssert(true)
        } catch {
            XCTFail()
        }
    }
    
    func testMultipleDocumentInstantiation() {
        let document1: Document = ["keyOne": "valueOne", "keyTwo": 42.3]
        let document2: Document = ["keyThree": "henk", "keyFour": 382]
        
        let data = document1.bsonData + document2.bsonData
        
        let reincarnations = try! Document.instantiateAll(data)
        XCTAssert(reincarnations.count == 2)
        
        XCTAssert(reincarnations[0].bsonData == document1.bsonData)
        XCTAssert(reincarnations[1].bsonData == document2.bsonData)
    }
    
    func testDocumentOne() {
        // {"cool32bitNumber":9001,"cool64bitNumber":{"$numberLong":"21312153544"},"currentTime":{"$date":"1970-01-17T19:46:29.266Z"},"documentTest":{"documentSubDoubleTest":13.37,"subArray":{"0":"henk","1":"fred","2":"kaas","3":"goudvis"}},"doubleTest":0.04,"nonRandomObjectId":{"$oid":"0123456789abcdef01234567"},"nothing":null,"stringTest":"foo"}
        let expected: [UInt8] = [121, 1, 0, 0, 13, 99, 111, 100, 101, 0, 28, 0, 0, 0, 99, 111, 110, 115, 111, 108, 101, 46, 108, 111, 103, 40, 34, 72, 101, 108, 108, 111, 32, 116, 104, 101, 114, 101, 34, 41, 59, 0, 15, 99, 111, 100, 101, 87, 105, 116, 104, 83, 99, 111, 112, 101, 0, 56, 0, 0, 0, 28, 0, 0, 0, 99, 111, 110, 115, 111, 108, 101, 46, 108, 111, 103, 40, 34, 72, 101, 108, 108, 111, 32, 116, 104, 101, 114, 101, 34, 41, 59, 0, 20, 0, 0, 0, 2, 104, 101, 121, 0, 6, 0, 0, 0, 104, 101, 108, 108, 111, 0, 0, 16, 99, 111, 111, 108, 51, 50, 98, 105, 116, 78, 117, 109, 98, 101, 114, 0, 41, 35, 0, 0, 18, 99, 111, 111, 108, 54, 52, 98, 105, 116, 78, 117, 109, 98, 101, 114, 0, 200, 167, 77, 246, 4, 0, 0, 0, 9, 99, 117, 114, 114, 101, 110, 116, 84, 105, 109, 101, 0, 18, 3, 164, 86, 0, 0, 0, 0, 3, 100, 111, 99, 117, 109, 101, 110, 116, 84, 101, 115, 116, 0, 102, 0, 0, 0, 1, 100, 111, 99, 117, 109, 101, 110, 116, 83, 117, 98, 68, 111, 117, 98, 108, 101, 84, 101, 115, 116, 0, 61, 10, 215, 163, 112, 189, 42, 64, 3, 115, 117, 98, 65, 114, 114, 97, 121, 0, 56, 0, 0, 0, 2, 48, 0, 5, 0, 0, 0, 104, 101, 110, 107, 0, 2, 49, 0, 5, 0, 0, 0, 102, 114, 101, 100, 0, 2, 50, 0, 5, 0, 0, 0, 107, 97, 97, 115, 0, 2, 51, 0, 8, 0, 0, 0, 103, 111, 117, 100, 118, 105, 115, 0, 0, 0, 1, 100, 111, 117, 98, 108, 101, 84, 101, 115, 116, 0, 123, 20, 174, 71, 225, 122, 164, 63, 7, 110, 111, 110, 82, 97, 110, 100, 111, 109, 79, 98, 106, 101, 99, 116, 73, 100, 0, 1, 35, 69, 103, 137, 171, 205, 239, 1, 35, 69, 103, 10, 110, 111, 116, 104, 105, 110, 103, 0, 2, 115, 116, 114, 105, 110, 103, 84, 101, 115, 116, 0, 4, 0, 0, 0, 102, 111, 111, 0, 0]
        
        let kittenDocument: Document = [
            "doubleTest": 0.04,
            "stringTest": "foo",
            "documentTest": *[
                "documentSubDoubleTest": 13.37,
                "subArray": *["henk", "fred", "kaas", "goudvis"]
            ],
            "nonRandomObjectId": try! ObjectId(hexString: "0123456789ABCDEF01234567"),
            "currentTime": NSDate(timeIntervalSince1970: Double(1453589266)),
            "cool32bitNumber": Int32(9001),
            "cool64bitNumber": 21312153544,
            "code": JavaScriptCode(code: "console.log(\"Hello there\");"),
            "codeWithScope": JavaScriptCode(code: "console.log(\"Hello there\");", scope: ["hey": "hello"]),
            "nothing": Null()
        ]
        
        print(expected)
        print(kittenDocument.bsonData)
        
        XCTAssert(expected == kittenDocument.bsonData)
        
        let dogUment = try! Document.instantiate(bsonData: kittenDocument.bsonData)
        
        XCTAssert(dogUment.bsonData == kittenDocument.bsonData)
        
        // test
//        var data = kittenDocument.bsonData
//        NSData(bytes: &data, length: data.count).writeToFile("/Users/robbert/Downloads/BSON.bson", atomically: false)
    }
    
    
}
