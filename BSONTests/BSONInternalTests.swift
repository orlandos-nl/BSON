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
