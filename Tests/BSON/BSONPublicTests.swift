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

#if os(Linux)
    import Glibc
#endif

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
        
        let nsDataThingy = NSData(try! Binary.instantiate(bsonData: binary.bsonData))
        
        let binaryTest = Binary(data: nsDataThingy)
        
        XCTAssert(binaryTest.data == data)
        
        let doc: Document = ["a": binaryTest]
        
        guard let newData: [UInt8] = (doc["a"] as? Binary)?.data else {
            XCTFail()
            return
        }
        
        XCTAssert(newData == data)
        
        let _ = try! Document.instantiate(bsonData: doc.bsonData)
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
        let expected: [UInt8] = [121, 1, 0, 0, 1, 100, 111, 117, 98, 108, 101, 84, 101, 115, 116, 0, 123, 20, 174, 71, 225, 122, 164, 63, 2, 115, 116, 114, 105, 110, 103, 84, 101, 115, 116, 0, 4, 0, 0, 0, 102, 111, 111, 0, 3, 100, 111, 99, 117, 109, 101, 110, 116, 84, 101, 115, 116, 0, 102, 0, 0, 0, 1, 100, 111, 99, 117, 109, 101, 110, 116, 83, 117, 98, 68, 111, 117, 98, 108, 101, 84, 101, 115, 116, 0, 61, 10, 215, 163, 112, 189, 42, 64, 4, 115, 117, 98, 65, 114, 114, 97, 121, 0, 56, 0, 0, 0, 2, 48, 0, 5, 0, 0, 0, 104, 101, 110, 107, 0, 2, 49, 0, 5, 0, 0, 0, 102, 114, 101, 100, 0, 2, 50, 0, 5, 0, 0, 0, 107, 97, 97, 115, 0, 2, 51, 0, 8, 0, 0, 0, 103, 111, 117, 100, 118, 105, 115, 0, 0, 0, 7, 110, 111, 110, 82, 97, 110, 100, 111, 109, 79, 98, 106, 101, 99, 116, 73, 100, 0, 1, 35, 69, 103, 137, 171, 205, 239, 1, 35, 69, 103, 9, 99, 117, 114, 114, 101, 110, 116, 84, 105, 109, 101, 0, 80, 254, 171, 112, 82, 1, 0, 0, 16, 99, 111, 111, 108, 51, 50, 98, 105, 116, 78, 117, 109, 98, 101, 114, 0, 41, 35, 0, 0, 18, 99, 111, 111, 108, 54, 52, 98, 105, 116, 78, 117, 109, 98, 101, 114, 0, 200, 167, 77, 246, 4, 0, 0, 0, 13, 99, 111, 100, 101, 0, 28, 0, 0, 0, 99, 111, 110, 115, 111, 108, 101, 46, 108, 111, 103, 40, 34, 72, 101, 108, 108, 111, 32, 116, 104, 101, 114, 101, 34, 41, 59, 0, 15, 99, 111, 100, 101, 87, 105, 116, 104, 83, 99, 111, 112, 101, 0, 56, 0, 0, 0, 28, 0, 0, 0, 99, 111, 110, 115, 111, 108, 101, 46, 108, 111, 103, 40, 34, 72, 101, 108, 108, 111, 32, 116, 104, 101, 114, 101, 34, 41, 59, 0, 20, 0, 0, 0, 2, 104, 101, 121, 0, 6, 0, 0, 0, 104, 101, 108, 108, 111, 0, 0, 10, 110, 111, 116, 104, 105, 110, 103, 0, 0]
        
        // the same as "expected" but as an object instead of list-of-bytes
        let kittenDocument: Document = [
            "doubleTest": 0.04,
            "stringTest": "foo",
            "documentTest": [
                "documentSubDoubleTest": 13.37,
                "subArray": ["henk", "fred", "kaas", "goudvis"] as Document
            ] as Document,
            "nonRandomObjectId": try! ObjectId("0123456789ABCDEF01234567"),
            "currentTime": NSDate(timeIntervalSince1970: Double(1453589266)),
            "cool32bitNumber": Int32(9001),
            "cool64bitNumber": 21312153544,
            "code": JavaScriptCode(code: "console.log(\"Hello there\");"),
            "codeWithScope": JavaScriptCode(code: "console.log(\"Hello there\");", scope: ["hey": "hello"]),
            "nothing": Null()
        ]
        
        // So do these 2 equal documents match?
        XCTAssert(expected == kittenDocument.bsonData)
        
        // Instantiate the BSONData
        let instantiatedExpected = try! Document.instantiate(bsonData: kittenDocument.bsonData)
        
        // Does this new Object's BSONData work?
        XCTAssert(instantiatedExpected.bsonData == kittenDocument.bsonData)
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
        
        do {
            let _ = try String.instantiate(bsonData: [0x00, 0x00, 0x00, 0x00, 0x00])
            XCTFail()
        } catch {}
        
        do {
            let _ = try String.instantiate(bsonData: [0x00, 0x00, 0x00, 0x00, 0x01])
            XCTFail()
        } catch {}
        
        do {
            let _ = try String.instantiate(bsonData: [0x00, 0x01, 0x00, 0x01, 0x01])
            XCTFail()
        } catch {}
        
        do {
            let _ = try String.instantiate(bsonData: "hoi".bsonData + [0x05])
            XCTFail()
        } catch {}
        
        let niceString = try! String.instantiate(bsonData: [0x01, 0x00, 0x00, 0x00, 0x00])
        XCTAssert(niceString == "")
        
        do {
            let _ = try String.instantiate(bsonData: [0x01, 0x02, 0x00, 0x00, 0x00])
            XCTFail()
        } catch {}
        
        let at = try! String.instantiateFromCString(bsonData: [0x40, 0x00])
        XCTAssert(at == "@")
        
        var consumed = 0
        
        let _ = try! String.instantiateFromCString(bsonData: [0x40, 0x00, 0x40, 0x00, 0x40, 0x00], consumedBytes: &consumed)
        XCTAssert(consumed == 2)
        
        do {
            let _ = try String.instantiateFromCString(bsonData: [0x40, 0x40])
            XCTFail()
        } catch {}
    }
    
    func testJavaScript() {
        do {
            let _ = try JavaScriptCode.instantiate(bsonData: "func()".bsonData)
            XCTFail()
        } catch {}
        
        do {
            var consumed = 0
            let _ = try JavaScriptCode.instantiate(bsonData: "func()".bsonData, consumedBytes: &consumed, type: .JavascriptCodeWithScope)
            XCTFail()
        } catch {}
        
        do {
            var consumed = 0
            let _ = try JavaScriptCode.instantiate(bsonData: [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00], consumedBytes: &consumed, type: .JavascriptCodeWithScope)
            XCTFail()
        } catch {}
        
        do {
            var consumed = 0
            let _ = try JavaScriptCode.instantiate(bsonData: [0x01, 0x01, 0x01, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00], consumedBytes: &consumed, type: .JavascriptCodeWithScope)
            XCTFail()
        } catch {}
        
        do {
            var consumed = 0
            let _ = try JavaScriptCode.instantiate(bsonData: [0x02, 0x00, 0x00, 0x00] + "asasdsdasdsasasds()".bsonData + ([] as Document).bsonData, consumedBytes: &consumed, type: .JavascriptCodeWithScope)
            XCTFail()
        } catch {}
        
        // TODO: instantiate some code with a trueCodeSize that's too small
        
        do {
            var consumed = 0
            let _ = try JavaScriptCode.instantiate(bsonData: [], consumedBytes: &consumed, type: .String)
            XCTFail()
        } catch {}
    }
    
    func testBooleanSerialization() {
        let falseData: [UInt8] = [0x00]
        let falseBoolean = try! Bool.instantiate(bsonData: falseData)
        
        XCTAssert(!falseBoolean, "Checking if 0x00 is false")
        
        let trueData: [UInt8] = [0x01]
        let trueBoolean = try! Bool.instantiate(bsonData: trueData)
        
        XCTAssert(trueBoolean, "Checking if 0x01 is true")
        
        do {
            let _ = try Bool.instantiate(bsonData: [])
            XCTFail()
        } catch {}
        
        do {
            let _ = try Bool.instantiate(bsonData: [0x03])
            XCTFail()
        } catch {}
        
        XCTAssert(true.bsonData == [0x01])
        XCTAssert(false.bsonData == [0x00])
    }
    
    func testTimestamp() {
        var consumed = 0
        
        let a = try! Timestamp.instantiate(bsonData: Int32(1455538099).bsonData + Int32(0).bsonData)
        
        let b = try! Timestamp.instantiate(bsonData: Int32(1455538099).bsonData + Int32(0).bsonData, consumedBytes: &consumed, type: .Int64)
        
        XCTAssert(consumed == 8)
        XCTAssert(a.bsonData == b.bsonData)
        XCTAssert(a.elementType == .Timestamp)
        
        if case .Fixed(let val) = Timestamp.bsonLength {
            XCTAssert(val == 8)
        }
    }
    
    func testRegex() {
        guard case .Undefined = RegularExpression.bsonLength else {
            XCTFail()
            return
        }
        
        let data = "/([A-Z])\\w+/g".cStringBsonData + "".cStringBsonData
        
        let myRegex = try! RegularExpression.instantiate(bsonData: data)
        
        guard myRegex.elementType == .RegularExpression else {
            XCTFail()
            return
        }
        
        guard myRegex.bsonData == data else {
            XCTFail()
            return
        }
        
        do {
            let _ = try RegularExpression.instantiate(bsonData: [0x01, 0x02])
            XCTFail()
        } catch {}
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
        let rawData: [UInt8] = [80, 254, 171, 112, 82, 1, 0, 0]
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
            XCTFail()
            return
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
        
        let id = try! ObjectId(sampleHex1)
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
        
        do {
            let objectIDsample = try ObjectId("507f191e810c19729de860ea")
            let objectIDsample2 = try ObjectId(bsonData: objectIDsample.bsonData)
            
            XCTAssert(objectIDsample.hexString == objectIDsample2.hexString)
        } catch {
            XCTFail()
        }
        
        do {
            let _ = try ObjectId("507f191e810c19729de860e")
            XCTFail()
        } catch {}
        
        do {
            let _ = try ObjectId("507f191e810c19729de860eae")
            XCTFail()
        } catch {}
        
        do {
            let _ = try ObjectId("507f191e810c19729de860ez")
            XCTFail()
        } catch {}
        
        do {
            let _ = try ObjectId.instantiate(bsonData: [0x00])
            XCTFail()
        } catch {}
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
            "aa": "bb", "cc": *[1, 2, 3]
            ],
            "d": 3.14]
        
        if let a: Int = testDocument["a"] as? Int {
            XCTAssert(a == 0)
            
        } else {
            XCTFail()
        }
        
        XCTAssert(testDocument["b"]! is Null)
        
        if let c: Document = testDocument["c"] as? Document {
            let subDoc: Document = ["aa": "bb", "cc": *[1, 2, 3]]
            
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
    
    func testMinMaxKey() {
        let max = try! MaxKey.instantiate(bsonData: [0x00])
        
        var consumed = 0
        let max2 = try! MaxKey.instantiate(bsonData: [0x00], consumedBytes: &consumed, type: .MaxKey)
        
        XCTAssert(consumed == 0)
        XCTAssert(max.bsonData == max2.bsonData)
        
        let min = try! MinKey.instantiate(bsonData: [0x00])
        
        let min2 = try! MinKey.instantiate(bsonData: [0x00], consumedBytes: &consumed, type: .MinKey)
        
        XCTAssert(consumed == 0)
        XCTAssert(min.bsonData == min2.bsonData)
    }
    
    func testTypes() {
        XCTAssert(Int64(123).elementType == .Int64)
        XCTAssert(Int32(123).elementType == .Int32)
        XCTAssert(true.elementType == .Boolean)
        XCTAssert(3.15.elementType == .Double)
        XCTAssert("henk".elementType == .String)
        XCTAssert(Null().elementType == .NullValue)
        XCTAssert(MinKey().elementType == .MinKey)
        XCTAssert(MaxKey().elementType == .MaxKey)
        XCTAssert(Binary(data: [0x01, 0x02, 0x03, 0x04, 0x03, 0x02, 0x01], subType: 53).elementType == .Binary)
    }
    
    func testDocumentInitialisation() {
        let document = Document(array: [0, 1, 3])
        
        XCTAssert(document[0] as? Int == 0)
        XCTAssert(document[1] as? Int == 1)
        XCTAssert(document[2] as? Int == 3)
        
        let otherDocument = Document(dictionaryLiteral: ("a", 1), ("b", true), ("c", "d"))
        
        XCTAssert(otherDocument["a"] as? Int == 1)
        XCTAssert(otherDocument["b"] as? Bool == true)
        XCTAssert(otherDocument["c"] as? String == "d")
    }
    
    func testAwesomeDocuments() {
        let expected: [UInt8] = [121, 1, 0, 0, 1, 100, 111, 117, 98, 108, 101, 84, 101, 115, 116, 0, 123, 20, 174, 71, 225, 122, 164, 63, 2, 115, 116, 114, 105, 110, 103, 84, 101, 115, 116, 0, 4, 0, 0, 0, 102, 111, 111, 0, 3, 100, 111, 99, 117, 109, 101, 110, 116, 84, 101, 115, 116, 0, 102, 0, 0, 0, 1, 100, 111, 99, 117, 109, 101, 110, 116, 83, 117, 98, 68, 111, 117, 98, 108, 101, 84, 101, 115, 116, 0, 61, 10, 215, 163, 112, 189, 42, 64, 4, 115, 117, 98, 65, 114, 114, 97, 121, 0, 56, 0, 0, 0, 2, 48, 0, 5, 0, 0, 0, 104, 101, 110, 107, 0, 2, 49, 0, 5, 0, 0, 0, 102, 114, 101, 100, 0, 2, 50, 0, 5, 0, 0, 0, 107, 97, 97, 115, 0, 2, 51, 0, 8, 0, 0, 0, 103, 111, 117, 100, 118, 105, 115, 0, 0, 0, 7, 110, 111, 110, 82, 97, 110, 100, 111, 109, 79, 98, 106, 101, 99, 116, 73, 100, 0, 1, 35, 69, 103, 137, 171, 205, 239, 1, 35, 69, 103, 9, 99, 117, 114, 114, 101, 110, 116, 84, 105, 109, 101, 0, 80, 254, 171, 112, 82, 1, 0, 0, 16, 99, 111, 111, 108, 51, 50, 98, 105, 116, 78, 117, 109, 98, 101, 114, 0, 41, 35, 0, 0, 18, 99, 111, 111, 108, 54, 52, 98, 105, 116, 78, 117, 109, 98, 101, 114, 0, 200, 167, 77, 246, 4, 0, 0, 0, 13, 99, 111, 100, 101, 0, 28, 0, 0, 0, 99, 111, 110, 115, 111, 108, 101, 46, 108, 111, 103, 40, 34, 72, 101, 108, 108, 111, 32, 116, 104, 101, 114, 101, 34, 41, 59, 0, 15, 99, 111, 100, 101, 87, 105, 116, 104, 83, 99, 111, 112, 101, 0, 56, 0, 0, 0, 28, 0, 0, 0, 99, 111, 110, 115, 111, 108, 101, 46, 108, 111, 103, 40, 34, 72, 101, 108, 108, 111, 32, 116, 104, 101, 114, 101, 34, 41, 59, 0, 20, 0, 0, 0, 2, 104, 101, 121, 0, 6, 0, 0, 0, 104, 101, 108, 108, 111, 0, 0, 10, 110, 111, 116, 104, 105, 110, 103, 0, 0]
        
        let kittenDocument: Document = [
            "doubleTest": 0.04,
            "stringTest": "foo",
            "documentTest": [
                "documentSubDoubleTest": 13.37,
                "subArray": ["henk", "fred", "kaas", "goudvis"] as Document
            ] as Document,
            "nonRandomObjectId": try! ObjectId("0123456789ABCDEF01234567"),
            "currentTime": NSDate(timeIntervalSince1970: Double(1453589266)),
            "cool32bitNumber": Int32(9001),
            "cool64bitNumber": 21312153544,
            "code": JavaScriptCode(code: "console.log(\"Hello there\");"),
            "codeWithScope": JavaScriptCode(code: "console.log(\"Hello there\");", scope: ["hey": "hello"]),
            "nothing": Null()
        ]
        
        XCTAssert(expected == kittenDocument.bsonData)
        
        let dogUment = try! Document(data: kittenDocument.bsonData)
        let dogUment2 = NSData(bytes: UnsafePointer<[UInt8]>(expected), length: expected.count)
        
        let dogUment3 = try! Document(data: dogUment2)
        
        XCTAssert(dogUment.bsonData == kittenDocument.bsonData)
        XCTAssert(dogUment.bsonData == dogUment3.bsonData)
        
        print(kittenDocument)
        
        do {
            let _ = try Document.instantiateAll([0x00])
            XCTFail()
        } catch {}
        // {"cool32bitNumber":9001,"cool64bitNumber":{"$numberLong":"21312153544"},"currentTime":{"$date":"1970-01-17T19:46:29.266Z"},"documentTest":{"documentSubDoubleTest":13.37,"subArray":{"0":"henk","1":"fred","2":"kaas","3":"goudvis"}},"doubleTest":0.04,"nonRandomObjectId":{"$oid":"0123456789abcdef01234567"},"nothing":null,"stringTest":"foo"}
        
        var expected2 : [UInt8] = [0x31, 0x00, 0x00, 0x00, 0x04]
        expected2 += "BSON".cStringBsonData
        expected2 += [0x00, 0x26, 0x00, 0x00, 0x00, 0x02, 0x30, 0x00, 0x08, 0x00, 0x00, 0x00]
        expected2 += "awesome".bsonData
        expected2 += [0x00, 0x01, 0x31, 0x00, 0x33, 0x33, 0x33, 0x33, 0x33, 0x33, 0x14, 0x40, 0x10, 0x32, 0x00, 0xc2, 0x07, 0x00, 0x00, 0x00, 0x00]
        
        var nullAsElementType = expected2
        nullAsElementType[4] = 0x00
        
        var unexpectedElementType = expected2
        unexpectedElementType[4] = 0x23
        
        let bsonCStringData = "BSON".cStringBsonData
        let halloStringData = "Hallo".bsonData
        
        var missingNullTerminator : [UInt8] = Int32(13).bsonData
        missingNullTerminator += [0x04]
        missingNullTerminator += Array(bsonCStringData[0..<(bsonCStringData.count - 1)])
        missingNullTerminator += [0x02]
        missingNullTerminator += Array(halloStringData[0..<(halloStringData.count - 1)])
        missingNullTerminator += [0x00]
        
        do {
            let _ = try Document.instantiate(bsonData: nullAsElementType)
            XCTFail()
        } catch {}
        
        do {
            let _ = try Document.instantiate(bsonData: unexpectedElementType)
            XCTFail()
        } catch {}
        
        // TODO: Missing tests for ParseError. No null terminators
    }
    
    func testDocumentSequenceType() {
        var kittenDocument: Document = [
            "doubleTest": 0.04,
            "stringTest": "foo",
            "documentTest": *[
                "documentSubDoubleTest": 13.37,
                "subArray": *["henk", "fred", "kaas", "goudvis"]
            ],
            "nonRandomObjectId": try! ObjectId("0123456789ABCDEF01234567"),
            "currentTime": NSDate(timeIntervalSince1970: Double(1453589266)),
            "cool32bitNumber": Int32(9001),
            "cool64bitNumber": 21312153544,
            "code": JavaScriptCode(code: "console.log(\"Hello there\");"),
            "codeWithScope": JavaScriptCode(code: "console.log(\"Hello there\");", scope: ["hey": "hello"]),
            "nothing": Null()
        ]
        
        // test == operator
        XCTAssert(kittenDocument["doubleTest"] ?== kittenDocument["doubleTest"]!)
        XCTAssert(kittenDocument["doubleTest"] ?== 0.04)
        XCTAssertFalse(kittenDocument["doubleTest"] ?== 0.05)
        
        let arrayThingy: Document = [
            "a", "b", 3, true, "kaas", "a"
        ]
        
        XCTAssert(arrayThingy[0]?.stringValue == "a")
        XCTAssert(arrayThingy[3]?.boolValue == true)
        
        XCTAssert(kittenDocument["doubleTest"] as? Double == 0.04)
        kittenDocument["doubleTest"] = "hoi"
        XCTAssert(kittenDocument["doubleTest"] as? String == "hoi")
        XCTAssert(kittenDocument[kittenDocument.indexForKey("doubleTest")!] as? String == "hoi")
        
        kittenDocument.updateValue("doubleTest", forKey: "doubleTest")
        XCTAssert(kittenDocument[kittenDocument.indexForKey("doubleTest")!] as? String == "doubleTest")
        
        let oldValue = kittenDocument.removeAtIndex(kittenDocument.startIndex)
        XCTAssert(oldValue.1.bsonData != kittenDocument[kittenDocument.startIndex]!.bsonData)
        
        XCTAssert(!kittenDocument.isEmpty)
        kittenDocument.removeAll()
        XCTAssert(kittenDocument.isEmpty)
    }
}
