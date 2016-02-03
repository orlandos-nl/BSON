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
        // {"currentTime":{"$date":"1970-01-17T19:46:29.266Z"},"cool32bitNumber":9001,"stringTest":"foo","doubleTest":0.04,"nonRandomObjectId":{"$oid":"0123456789abcdef01234567"},"cool64bitNumber":{"$numberLong":"21312153544"},"documentTest":{"subArray":{"2":"kaas","1":"fred","0":"henk","3":"goudvis"},"documentSubDoubleTest":13.37}}
        let expected: [UInt8] = [0x0C, 0x01, 0x00, 0x00, 0x10, 0x63, 0x6F, 0x6F, 0x6C, 0x33, 0x32, 0x62, 0x69, 0x74, 0x4E, 0x75, 0x6D, 0x62, 0x65, 0x72, 0x00, 0x29, 0x23, 0x00, 0x00, 0x12, 0x63, 0x6F, 0x6F, 0x6C, 0x36, 0x34, 0x62, 0x69, 0x74, 0x4E, 0x75, 0x6D, 0x62, 0x65, 0x72, 0x00, 0xC8, 0xA7, 0x4D, 0xF6, 0x04, 0x00, 0x00, 0x00, 0x09, 0x63, 0x75, 0x72, 0x72, 0x65, 0x6E, 0x74, 0x54, 0x69, 0x6D, 0x65, 0x00, 0x12, 0x03, 0xA4, 0x56, 0x00, 0x00, 0x00, 0x00, 0x03, 0x64, 0x6F, 0x63, 0x75, 0x6D, 0x65, 0x6E, 0x74, 0x54, 0x65, 0x73, 0x74, 0x00, 0x66, 0x00, 0x00, 0x00, 0x01, 0x64, 0x6F, 0x63, 0x75, 0x6D, 0x65, 0x6E, 0x74, 0x53, 0x75, 0x62, 0x44, 0x6F, 0x75, 0x62, 0x6C, 0x65, 0x54, 0x65, 0x73, 0x74, 0x00, 0x3D, 0x0A, 0xD7, 0xA3, 0x70, 0xBD, 0x2A, 0x40, 0x03, 0x73, 0x75, 0x62, 0x41, 0x72, 0x72, 0x61, 0x79, 0x00, 0x38, 0x00, 0x00, 0x00, 0x02, 0x30, 0x00, 0x05, 0x00, 0x00, 0x00, 0x68, 0x65, 0x6E, 0x6B, 0x00, 0x02, 0x31, 0x00, 0x05, 0x00, 0x00, 0x00, 0x66, 0x72, 0x65, 0x64, 0x00, 0x02, 0x32, 0x00, 0x05, 0x00, 0x00, 0x00, 0x6B, 0x61, 0x61, 0x73, 0x00, 0x02, 0x33, 0x00, 0x08, 0x00, 0x00, 0x00, 0x67, 0x6F, 0x75, 0x64, 0x76, 0x69, 0x73, 0x00, 0x00, 0x00, 0x01, 0x64, 0x6F, 0x75, 0x62, 0x6C, 0x65, 0x54, 0x65, 0x73, 0x74, 0x00, 0x7B, 0x14, 0xAE, 0x47, 0xE1, 0x7A, 0xA4, 0x3F, 0x07, 0x6E, 0x6F, 0x6E, 0x52, 0x61, 0x6E, 0x64, 0x6F, 0x6D, 0x4F, 0x62, 0x6A, 0x65, 0x63, 0x74, 0x49, 0x64, 0x00, 0x01, 0x23, 0x45, 0x67, 0x89, 0xAB, 0xCD, 0xEF, 0x01, 0x23, 0x45, 0x67, 0x0A, 0x6E, 0x6F, 0x74, 0x68, 0x69, 0x6E, 0x67, 0x00, 0x02, 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x54, 0x65, 0x73, 0x74, 0x00, 0x04, 0x00, 0x00, 0x00, 0x66, 0x6F, 0x6F, 0x00, 0x00]
        
        let kittenDocument: Document = [
            "doubleTest": 0.04,
            "stringTest": "foo",
            "documentTest": *[
                "documentSubDoubleTest": 13.37,
                "subArray": ["henk", "fred", "kaas", "goudvis"]
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
            let _ = try Int32.instantiate(bsonData: [0xc2, 0x07, 0x00, 0x00, 0x00])
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
            let _ = try Int.instantiate(bsonData: [0x01, 0x00, 0x00, 0x04, 0x00, 0x00, 0x06, 0x08, 0x04])
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
