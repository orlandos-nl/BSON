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

class BSONInternalTests: XCTestCase {
    
    // for old snapshot, removed throws
    var allTests : [(String, () -> Void)] {
        return [
                ("testDocumentOne", testDocumentOne),
                ("testDoubleSerialization", testDoubleSerialization),
                ("testStringSerialization", testStringSerialization),
                ("testBooleanSerialization", testBooleanSerialization),
                ("testInt32Serialization", testInt32Serialization),
                ("testInt64Serialization", testInt64Serialization),
                ("testTimestampSerialization", testDateTimeSerialization),
                ("testDocumentSerialization", testDocumentSerialization),
                ("testArrayConvertableToDocument", testArrayConvertableToDocument),
                ("testDictionaryConvertableToDocument", testDictionaryConvertableToDocument),
                ("testObjectIdSerialization", testObjectIdSerialization),
                ("testNullSerialization", testNullSerialization),
                ("testRegexSerialization", testRegexSerialization),
                ("testDocumentSubscript", testDocumentSubscript),
        ]
    }
    
    func testDocumentOne() {
        // {"cool32bitNumber":9001,"cool64bitNumber":{"$numberLong":"21312153544"},"currentTime":{"$date":"1970-01-17T19:46:29.266Z"},"documentTest":{"documentSubDoubleTest":13.37,"subArray":{"0":"henk","1":"fred","2":"kaas","3":"goudvis"}},"doubleTest":0.04,"nonRandomObjectId":{"$oid":"0123456789abcdef01234567"},"nothing":null,"stringTest":"foo"}
        let expected: [UInt8] = [12, 1, 0, 0, 16, 99, 111, 111, 108, 51, 50, 98, 105, 116, 78, 117, 109, 98, 101, 114, 0, 41, 35, 0, 0, 18, 99, 111, 111, 108, 54, 52, 98, 105, 116, 78, 117, 109, 98, 101, 114, 0, 200, 167, 77, 246, 4, 0, 0, 0, 9, 99, 117, 114, 114, 101, 110, 116, 84, 105, 109, 101, 0, 18, 3, 164, 86, 0, 0, 0, 0, 3, 100, 111, 99, 117, 109, 101, 110, 116, 84, 101, 115, 116, 0, 102, 0, 0, 0, 1, 100, 111, 99, 117, 109, 101, 110, 116, 83, 117, 98, 68, 111, 117, 98, 108, 101, 84, 101, 115, 116, 0, 61, 10, 215, 163, 112, 189, 42, 64, 3, 115, 117, 98, 65, 114, 114, 97, 121, 0, 56, 0, 0, 0, 2, 48, 0, 5, 0, 0, 0, 104, 101, 110, 107, 0, 2, 49, 0, 5, 0, 0, 0, 102, 114, 101, 100, 0, 2, 50, 0, 5, 0, 0, 0, 107, 97, 97, 115, 0, 2, 51, 0, 8, 0, 0, 0, 103, 111, 117, 100, 118, 105, 115, 0, 0, 0, 1, 100, 111, 117, 98, 108, 101, 84, 101, 115, 116, 0, 123, 20, 174, 71, 225, 122, 164, 63, 7, 110, 111, 110, 82, 97, 110, 100, 111, 109, 79, 98, 106, 101, 99, 116, 73, 100, 0, 1, 35, 69, 103, 137, 171, 205, 239, 1, 35, 69, 103, 10, 110, 111, 116, 104, 105, 110, 103, 0, 2, 115, 116, 114, 105, 110, 103, 84, 101, 115, 116, 0, 4, 0, 0, 0, 102, 111, 111, 0, 0]
        
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
    
    func testDoubleSerialization() {
        // This is 5.05
        let rawData: [UInt8] = [0x33, 0x33, 0x33, 0x33, 0x33, 0x33, 0x14, 0x40]
        let double = try! Double.instantiate(bsonData: rawData)
        XCTAssertEqual(double, 5.05, "Instantiating a Double from BSON data works correctly")
        
        let generatedData = 5.05.bsonData
        XCTAssert(generatedData == rawData, "Converting a Double to BSON data results in the correct data")
        
        // Test errors
        do {
            let _ = try Double.instantiate(bsonData: [0x04])
            XCTFail()
        } catch DeserializationError.InvalidElementSize {
            XCTAssert(true)
        } catch {
            XCTFail()
        }
    }
    
    func testStringSerialization() {
        // This is "ABCD"
        let rawData: [UInt8] = [0x41, 0x42, 0x43, 0x44, 0x00]
        let result = "ABCD"
        
        let string = try! String.instantiateFromCString(bsonData: Array(rawData[0...rawData.count - 2]))
        XCTAssertEqual(string, result, "Instantiating a String from BSON data works correctly")
        
        let generatedData = result.cStringBsonData
        XCTAssertEqual(generatedData, rawData, "Converting a String to BSON data results in the correct data")
    }
    
    func testBooleanSerialization() {
        let falseData: [UInt8] = [0x00]
        let falseBoolean = try! Bool.instantiate(bsonData: falseData)
        
        XCTAssert(!falseBoolean, "Checking if 0x00 is false")
        
        let trueData: [UInt8] = [0x01]
        let trueBoolean = try! Bool.instantiate(bsonData: trueData)
        
        XCTAssert(trueBoolean, "Checking if 0x01 is true")
    }
    
    func testInt32Serialization() {
        let rawData: [UInt8] = [0xc2, 0x07, 0x00, 0x00]
        let double = try! Int32.instantiate(bsonData: rawData)
        XCTAssertEqual(double, 1986, "Instantiating an int32 from BSON data works correctly")
        
        let generatedData = (1986 as Int32).bsonData
        XCTAssert(generatedData == rawData, "Converting an int32 to BSON data results in the correct data")
        
        // Test errors
        do {
            let _ = try Int32.instantiate(bsonData: [0xc2, 0x07, 0x00])
            XCTFail()
        } catch DeserializationError.InvalidElementSize {
            // fine!
            XCTAssert(true)
        } catch {
            XCTFail()
        }
    }
    
    func testInt64Serialization() {
        let rawData: [UInt8] = [0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]
        let double = try! Int.instantiate(bsonData: rawData)
        XCTAssertEqual(double, 1, "Instantiating an integer from BSON data works correctly")
        
        let generatedData = (1 as Int).bsonData
        XCTAssert(generatedData == rawData, "Converting an integer to BSON data results in the correct data")
        
        // Test errors
        do {
            let _ = try Int.instantiate(bsonData: [0x01, 0x00, 0x00, 0x00, 0x06, 0x08, 0x04])
            XCTFail()
        } catch DeserializationError.InvalidElementSize {
            // fine!
            XCTAssert(true)
        } catch {
            XCTFail()
        }
    }
    
    func testDateTimeSerialization() {
        // 2016-01-23 22:47:46 UTC
        let rawData: [UInt8] = [0x12, 0x03, 0xa4, 0x56, 0x00, 0x00, 0x00, 0x00]
        let date = try! NSDate.instantiate(bsonData: rawData)
        
        XCTAssertEqual(date.timeIntervalSince1970, 1453589266, "Instantiating NSDate from BSON data works correctly")
        
        let generatedData = NSDate(timeIntervalSince1970: Double(1453589266)).bsonData
        XCTAssert(generatedData == rawData, "Converting NSDate to BSON data results in the corrrect timestamp")
    }
    
    func testDocumentSerialization() {
        // {"hello": "world"}
        let firstBSON: [UInt8] = [0x16, 0x00, 0x00, 0x00, 0x02, 0x68, 0x65, 0x6c, 0x6c, 0x6f, 0x00, 0x06, 0x00, 0x00, 0x00, 0x77, 0x6f, 0x72, 0x6c, 0x64, 0x00, 0x00]
        let secondBSON: [UInt8] = [0x31, 0x00, 0x00, 0x00, 0x04, 0x42, 0x53, 0x4f, 0x4e, 0x00, 0x26, 0x00, 0x00, 0x00, 0x02, 0x30, 0x00, 0x08, 0x00, 0x00, 0x00, 0x61, 0x77, 0x65, 0x73, 0x6f, 0x6d, 0x65, 0x00, 0x01, 0x31, 0x00, 0x33, 0x33, 0x33, 0x33, 0x33, 0x33, 0x14, 0x40, 0x10, 0x32, 0x00, 0xc2, 0x07, 0x00, 0x00, 0x00, 0x00]
        
        let firstDocument = try! Document.instantiate(bsonData: firstBSON)
  
        XCTAssert(firstDocument.elements["hello"] as! String == "world", "Our document contains the proper information")
        
        XCTAssertEqual(firstDocument.bsonData, firstBSON, "FirstBSON has an equal output to the instantiation array")
        
        // {"BSON": ["awesome", 5.05, 1986]}
        let secondDocument = try! Document.instantiate(bsonData: secondBSON)
        
        XCTAssertEqual(secondDocument.bsonData, secondBSON, "SecondBSON has an equal output to the instantiation array")
        
        guard let subscripted: Document = secondDocument.elements["BSON"] as? Document else {
            abort()
        }
        
        XCTAssert(subscripted.elements["0"] as! String == "awesome")
    }
    
    func testArrayConvertableToDocument() {
        let docOne: Document = ["a", "b", "c"]
        
        XCTAssert(docOne.elements.count == 3)
        XCTAssert(docOne.elementType == .Array)
        
        XCTAssert(docOne.elements["1"] as! String == "b")
    }
    
    func testDictionaryConvertableToDocument() {
        let docOne: Document = ["hai": Int32(3), "henk": "Hont", "kat": true]
        
        XCTAssert(docOne.elements.count == 3)
        XCTAssert(docOne.elementType == .Document)
        
        XCTAssert(docOne.elements["hai"] as! Int32 == 3)
        XCTAssert(docOne.elements["henk"] as! String == "Hont")
        XCTAssert(docOne.elements["kat"] as! Bool == true)
    }
    
    func testObjectIdSerialization() {
        // ObjectId initialization and reading
        let sampleHex1 = "56a78f3e308b914cac362bb8"
        
        let id = try! ObjectId(hexString: sampleHex1)
        XCTAssertEqual(id.hexString, sampleHex1)
        
        // ObjectId generation
        let randomId = ObjectId()
        XCTAssertEqual(randomId.data.count, 12)
        
        // Test errors
        do {
            let _ = try ObjectId(bsonData: [0x04, 0x04, 0x02])
            XCTFail()
        } catch DeserializationError.InvalidElementSize {
            XCTAssert(true)
        } catch {
            XCTFail()
        }
    }
    
    // Yes, really.
    func testNullSerialization() {
        // Does null contain no data?
        let null = Null()
        XCTAssert(null.bsonData == [])
        
        // IF I instantiate null without data.. will it work?
        let othernull = try! Null.instantiate(bsonData: [])
        XCTAssert(othernull.bsonData == [])
    }

    func testRegexSerialization() {
        // RegularExpression initialization and testing
        //let sampleRegex = try! RegularExpression(pattern: "/^(https?:\\/\\/)?([\\da-z\\.-]+)\\.([a-z\\.]{2,6})([\\/\\w \\.-]*)*\\/?$/", options: "")

        //XCTAssert(sampleRegex.test("https://www.fsf.org/about/", options: []))
    }
    
    func testDocumentSubscript() {
        let testDocument: Document = ["a": 0, "b": Null(), "c": *[
                "aa": "bb", "cc": [1, 2, 3]
            ],
        "d": 3.14]
        
        if let a: Int = testDocument["a"] as? Int {
            XCTAssert(a == 0)
            
        } else {
            XCTFail()
        }
        
        XCTAssert(testDocument["b"]! is Null)
        
        if let c: Document = testDocument["c"] as? Document {
            let subDoc: Document = ["aa": "bb", "cc": [1, 2, 3]]
            
            XCTAssert(c.bsonData == subDoc.bsonData)
            
            XCTAssert(c["aa"] as? String == "bb")
            
            if let cc: Document = c["cc"] as? Document {
                XCTAssert(cc.bsonData == ([1, 2, 3] as Document).bsonData)
                XCTAssert(cc[0] as! Int == 1)
                XCTAssert(cc[2] as! Int == 3)
                XCTAssert(cc.count == 3)
                
                var ccCopy = cc
                
                for (key, value) in ccCopy {
                    guard let newValue = ccCopy.removeValueForKey(key) else {
                        XCTFail()
                        break
                    }
                    
                    if newValue.bsonData != value.bsonData {
                        XCTFail()
                    }
                }
                
            } else {
                XCTFail()
            }
            
        } else {
            XCTFail()
        }
        
        if let d: Double = testDocument["d"] as? Double {
            XCTAssert(d == 3.14)
        } else {
            XCTFail()
        }
    }
}
