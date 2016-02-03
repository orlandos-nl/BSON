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
    var allTests : [(String, () -> Void)] {
        return [
            ("testBasics", testBasics),
            ("testBinarySerialization", testBinarySerialization ),
            ("testMultipleDocumentInstantiation", testMultipleDocumentInstantiation ),
            ("testDocumentOne", testDocumentOne),
            ("testDoubleSerialization", testDoubleSerialization),
            ("testStringSerialization", testStringSerialization),
            ("testBooleanSerialization", testBooleanSerialization),
            ("testInt32Serialization", testInt32Serialization),
            ("testInt64Serialization", testInt64Serialization),
            ("testDateTimeSerialization", testDateTimeSerialization),
            ("testDocumentSerialization", testDocumentSerialization),
            ("testArrayConvertableToDocument", testArrayConvertableToDocument),
            ("testDictionaryConvertableToDocument", testDictionaryConvertableToDocument),
            ("testObjectIdSerialization", testObjectIdSerialization),
            ("testNullSerialization", testNullSerialization),
            ("testRegexSerialization", testRegexSerialization),
            ("testDocumentSubscript", testDocumentSubscript),
            // Other tests go here
        ]
    }
    
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
        let rawData: [UInt8] = [0x05, 0x00, 0x00, 0x00, 0x41, 0x42, 0x43, 0x44, 0x00]
        let result = "ABCD"
        
        let string = try! String.instantiate(bsonData: rawData)
        XCTAssertEqual(string, result, "Instantiating a String from BSON data works correctly")
        
        let generatedData = result.bsonData
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
        let firstBSON: [UInt8] = [0x16, 0x00, 0x00, 0x00, 0x02, 0x68, 0x65, 0x6c, 0x6c, 0x6f, 0x00, 0x06, 0x00, 0x00, 0x00, 0x77, 0x6f, 0x72, 0x6c, 0x64, 0x00, 0x00]
        let secondBSON: [UInt8] = [0x31, 0x00, 0x00, 0x00, 0x04, 0x42, 0x53, 0x4f, 0x4e, 0x00, 0x26, 0x00, 0x00, 0x00, 0x02, 0x30, 0x00, 0x08, 0x00, 0x00, 0x00, 0x61, 0x77, 0x65, 0x73, 0x6f, 0x6d, 0x65, 0x00, 0x01, 0x31, 0x00, 0x33, 0x33, 0x33, 0x33, 0x33, 0x33, 0x14, 0x40, 0x10, 0x32, 0x00, 0xc2, 0x07, 0x00, 0x00, 0x00, 0x00]
        
        let firstDocument = try! Document.instantiate(bsonData: firstBSON)
        
        XCTAssert(firstDocument["hello"] as! String == "world", "Our document contains the proper information")
        
        XCTAssertEqual(firstDocument.bsonData, firstBSON, "FirstBSON has an equal output to the instantiation array")
        
        // {"BSON": ["awesome", 5.05, 1986]}
        let secondDocument = try! Document.instantiate(bsonData: secondBSON)
        
        XCTAssertEqual(secondDocument.bsonData, secondBSON, "SecondBSON has an equal output to the instantiation array")
        
        guard let subscripted: Document = secondDocument["BSON"] as? Document else {
            abort()
        }
        
        XCTAssert(subscripted["0"] as! String == "awesome")
    }
    
    func testArrayConvertableToDocument() {
        let docOne: Document = ["a", "b", "c"]
        
        XCTAssert(docOne.count == 3)
        XCTAssert(docOne.elementType == .Array)
        
        XCTAssert(docOne["1"] as! String == "b")
    }
    
    func testDictionaryConvertableToDocument() {
        let docOne: Document = ["hai": Int32(3), "henk": "Hont", "kat": true]
        
        XCTAssert(docOne.count == 3)
        XCTAssert(docOne.elementType == .Document)
        
        XCTAssert(docOne["hai"] as! Int32 == 3)
        XCTAssert(docOne["henk"] as! String == "Hont")
        XCTAssert(docOne["kat"] as! Bool == true)
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
