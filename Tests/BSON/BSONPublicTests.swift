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

// TODO: Test boolean `false`
// TODO: Test validation of invalid documents
// TODO: Test DocumentIndex

class BSONPublicTests: XCTestCase {
    static var allTests : [(String, (BSONPublicTests) -> () throws -> Void)] {
        return [
            ("testCompare", testCompare),
            ("testBasics", testBasics),
            ("testBinarySerialization", testBinarySerialization ),
            ("testMultipleDocumentInstantiation", testMultipleDocumentInstantiation ),
            ("testDocumentOne", testDocumentOne),
            ("testStringSerialization", testStringSerialization),
            ("testDocumentSerialization", testDocumentSerialization),
            ("testArrayConvertableToDocument", testArrayConvertableToDocument),
            ("testDictionaryConvertableToDocument", testDictionaryConvertableToDocument),
            ("testObjectIdSerialization", testObjectIdSerialization),
            ("testDocumentSubscript", testDocumentSubscript),
            ("testDocumentInitialisation", testDocumentInitialisation),
            ("testAwesomeDocuments", testAwesomeDocuments),
            ("testDocumentSequenceType", testDocumentSequenceType),
            ("testDeserializationPerformance", testDeserializationPerformance),
            ("testSerializationPerformance", testSerializationPerformance),
//            ("testSubscriptPerformance", testSubscriptPerformance),
//            ("testFullDocumentPerformance", testFullDocumentPerformance),
//            ("testValidation", testValidation),
            // Other tests go here
        ]
    }
    
    func testCompare() {
        let document: Document = ["double": 4.0, "int64": 4]
        XCTAssert(document["double"] == document["int64"])
        XCTAssertFalse(document["double"] === document["int64"])
    }
    
    func testBasics() {
        var document: Document = [
            "hello": "I am a document created trough the public API",
            "subdocument": ["hello", "mother of god"]
        ]
        
        XCTAssertEqual(document.count, 2)
        
        document["henk"] = "fred"
        document["harrie"] = ~document["henk"].string
        
        XCTAssertEqual(document["harrie"], document["henk"])
        XCTAssertEqual(document["harrie"].string, "fred")
    }
    
    func testBinarySerialization() {
        let data: [UInt8] = [0x01, 0x02, 0x03, 0x06, 0x0c, 0x18, 0x30, 0x60]
        
        // Instantiating with 8 bytes of data and converting to BSON data
        let binary = Value.binary(subtype: .generic, data: data)
        XCTAssert(binary.bytes == ([8, 0, 0, 0, 0] as [UInt8] + data))
        
        // Try instantiating with a subtype
        let otherBinary = Value.binary(subtype: .userDefined(0x90), data: data)
        XCTAssert(otherBinary.bytes == ([8, 0, 0, 0, 144] as [UInt8] + data))
    }
    
    func testMultipleDocumentInstantiation() {
        let document1: Document = ["keyOne": "valueOne", "keyTwo": 42.3]
        let document2: Document = ["keyThree": "henk", "keyFour": 382]
        
        let data = document1.bytes + document2.bytes
        
        let reincarnations = [Document](bsonBytes: data)
        XCTAssertEqual(reincarnations.count, 2)
        
        XCTAssertEqual(reincarnations[0].bytes, document1.bytes)
        XCTAssertEqual(reincarnations[1].bytes, document2.bytes)
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
                "subArray": ["henk", "fred", "kaas", "goudvis"]
            ],
            "nonRandomObjectId": try! ~ObjectId("0123456789ABCDEF01234567"),
            "currentTime": .dateTime(Date(timeIntervalSince1970: Double(1453589266))),
            "cool32bitNumber": .int32(9001),
            "cool64bitNumber": 21312153544,
            "code": .javascriptCode("console.log(\"Hello there\");"),
            "codeWithScope": .javascriptCodeWithScope(code: "console.log(\"Hello there\");", scope: ["hey": "hello"]),
            "nothing": .null
        ]
        
        // So do these 2 equal documents match?
        XCTAssert(expected == kittenDocument.bytes)
        
        // Instantiate the BSONData
        let instantiatedExpected = Document(data: kittenDocument.bytes)
        
        // Does this new Object's BSONData work?
        XCTAssert(instantiatedExpected.bytes == kittenDocument.bytes)
    }
    
    func testStringSerialization() {
        // This is "ABCD"
        let rawData: [UInt8] = [0x05, 0x00, 0x00, 0x00, 0x41, 0x42, 0x43, 0x44, 0x00]
        let result = "ABCD"
        
        let string = try! String.instantiate(bytes: rawData)
        XCTAssertEqual(string, result, "Instantiating a String from BSON data works correctly")
        
        let generatedData = result.bytes
        XCTAssertEqual(generatedData, rawData, "Converting a String to BSON data results in the correct data")
        
        do {
            let _ = try String.instantiate(bytes: [0x00, 0x00, 0x00, 0x00, 0x00])
            XCTFail()
        } catch {}
        
        do {
            let _ = try String.instantiate(bytes: [0x00, 0x00, 0x00, 0x00, 0x01])
            XCTFail()
        } catch {}
        
        do {
            let _ = try String.instantiate(bytes: [0x00, 0x01, 0x00, 0x01, 0x01])
            XCTFail()
        } catch {}
        
        do {
            let _ = try String.instantiate(bytes: "hoi".bytes + [0x05])
            XCTFail()
        } catch {}
        
        let niceString = try! String.instantiate(bytes: [0x01, 0x00, 0x00, 0x00, 0x00])
        XCTAssert(niceString == "")
        
        do {
            let _ = try String.instantiate(bytes: [0x01, 0x02, 0x00, 0x00, 0x00])
            XCTFail()
        } catch {}
        
        let at = try! String.instantiateFromCString(bytes: [0x40, 0x00])
        XCTAssert(at == "@")
        
        var consumed = 0
        
        let _ = try! String.instantiateFromCString(bytes: [0x40, 0x00, 0x40, 0x00, 0x40, 0x00], consumedBytes: &consumed)
        XCTAssert(consumed == 2)
        
        do {
            let _ = try String.instantiateFromCString(bytes: [0x40, 0x40])
            XCTFail()
        } catch {}
    }
    
    func testDocumentSerialization() {
        let firstBSON: [UInt8] = [0x16, 0x00, 0x00, 0x00, 0x02, 0x68, 0x65, 0x6c, 0x6c, 0x6f, 0x00, 0x06, 0x00, 0x00, 0x00, 0x77, 0x6f, 0x72, 0x6c, 0x64, 0x00, 0x00]
        let secondBSON: [UInt8] = [0x31, 0x00, 0x00, 0x00, 0x04, 0x42, 0x53, 0x4f, 0x4e, 0x00, 0x26, 0x00, 0x00, 0x00, 0x02, 0x30, 0x00, 0x08, 0x00, 0x00, 0x00, 0x61, 0x77, 0x65, 0x73, 0x6f, 0x6d, 0x65, 0x00, 0x01, 0x31, 0x00, 0x33, 0x33, 0x33, 0x33, 0x33, 0x33, 0x14, 0x40, 0x10, 0x32, 0x00, 0xc2, 0x07, 0x00, 0x00, 0x00, 0x00]
        
        let firstDocument = Document(data: firstBSON)
        
        XCTAssert(firstDocument["hello"].string == "world", "Our document contains the proper information")
        
        XCTAssertEqual(firstDocument.bytes, firstBSON, "FirstBSON has an equal output to the instantiation array")
        
        // {"BSON": ["awesome", 5.05, 1986]}
        let secondDocument = Document(data: secondBSON)
        
        XCTAssertEqual(secondDocument.bytes, secondBSON, "SecondBSON has an equal output to the instantiation array")
        
        guard let subscripted: Document = secondDocument["BSON"].document else {
            XCTFail()
            return
        }
        
        XCTAssert(subscripted["0"].string == "awesome")
    }
    
    func testArrayConvertableToDocument() {
        let docOne: Document = ["a", "b", "c"]
        
        XCTAssertEqual(docOne.count, 3)
        
        XCTAssertEqual(docOne["1"].string, "b")
    }
    
    func testDictionaryConvertableToDocument() {
        let docOne: Document = ["hai": .int32(3), "henk": "Hont", "kat": true]
        
        XCTAssertEqual(docOne.count, 3)
        
        XCTAssertEqual(docOne["hai"].int32, 3)
        XCTAssertEqual(docOne["henk"].string, "Hont")
        XCTAssertEqual(docOne["kat"].bool, true)
    }
    
    func testObjectIdSerialization() {
        // ObjectId initialization and reading
        let sampleHex1 = "56a78f3e308b914cac362bb8"
        
        let id = try! ~ObjectId(sampleHex1)
        XCTAssertEqual(id.string, sampleHex1)
        
        // Test errors
        do {
            let _ = try ObjectId(bytes: [0x04, 0x04, 0x02])
            XCTFail()
        } catch DeserializationError.InvalidElementSize {
            XCTAssert(true)
        } catch {
            XCTFail()
        }
        
        do {
            let objectIDsample = try ObjectId("507f191e810c19729de860ea")
            let objectIDsample2 = try ObjectId(bytes: (~objectIDsample).bytes)
            
            XCTAssertEqual(objectIDsample.hexString, objectIDsample2.hexString)
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
            let _ = try ObjectId(bytes: [0x00])
            XCTFail()
        } catch {}
    }
    
    func testDocumentSubscript() {
        let testDocument: Document = ["a": 0, "b": .null, "c": [
            "aa": "bb", "cc": [1, 2, 3]
            ],
            "d": 3.14]
        
        XCTAssert(testDocument["a"].int == 0)
        
        guard case .null = testDocument["b"] else {
            XCTFail()
            return
        }
        
        if let c = testDocument["c"].documentValue {
            let subDoc: Document = ["aa": "bb", "cc": [1, 2, 3]]
            
            XCTAssert(c.bytes == subDoc.bytes)
            
            XCTAssertEqual(c["aa"].string, "bb")
            
            if let cc = c["cc"].documentValue {
                XCTAssertEqual(cc.bytes, ([1, 2, 3] as Document).bytes)
                XCTAssertEqual(cc[0].int, 1)
                XCTAssertEqual(cc[2].int, 3)
                XCTAssertEqual(cc.count, 3)
                
                var ccCopy = cc
                
                for (key, value) in ccCopy {
                    guard let newValue = ccCopy.removeValue(forKey: key) else {
                        XCTFail()
                        break
                    }
                    
                    if newValue.bytes != value.bytes {
                        XCTFail()
                    }
                }
                
            } else {
                XCTFail()
            }
            
        } else {
            XCTFail()
        }
        
        XCTAssertEqual(testDocument["d"].doubleValue, 3.14)
    }
    
    func testDocumentInitialisation() {
        let document = Document(array: [0, 1, 3])
        
        XCTAssertEqual(document[0].int, 0)
        XCTAssertEqual(document[1].int, 1)
        XCTAssertEqual(document[2].int, 3)
        
        let otherDocument = Document(dictionaryLiteral: ("a", 1), ("b", true), ("c", "d"))
        
        XCTAssertEqual(otherDocument["a"].int, 1)
        XCTAssertEqual(otherDocument["b"].bool, true)
        XCTAssertEqual(otherDocument["c"].string, "d")
    }
    
    func testAwesomeDocuments() {
        let expected: [UInt8] = [121, 1, 0, 0, 1, 100, 111, 117, 98, 108, 101, 84, 101, 115, 116, 0, 123, 20, 174, 71, 225, 122, 164, 63, 2, 115, 116, 114, 105, 110, 103, 84, 101, 115, 116, 0, 4, 0, 0, 0, 102, 111, 111, 0, 3, 100, 111, 99, 117, 109, 101, 110, 116, 84, 101, 115, 116, 0, 102, 0, 0, 0, 1, 100, 111, 99, 117, 109, 101, 110, 116, 83, 117, 98, 68, 111, 117, 98, 108, 101, 84, 101, 115, 116, 0, 61, 10, 215, 163, 112, 189, 42, 64, 4, 115, 117, 98, 65, 114, 114, 97, 121, 0, 56, 0, 0, 0, 2, 48, 0, 5, 0, 0, 0, 104, 101, 110, 107, 0, 2, 49, 0, 5, 0, 0, 0, 102, 114, 101, 100, 0, 2, 50, 0, 5, 0, 0, 0, 107, 97, 97, 115, 0, 2, 51, 0, 8, 0, 0, 0, 103, 111, 117, 100, 118, 105, 115, 0, 0, 0, 7, 110, 111, 110, 82, 97, 110, 100, 111, 109, 79, 98, 106, 101, 99, 116, 73, 100, 0, 1, 35, 69, 103, 137, 171, 205, 239, 1, 35, 69, 103, 9, 99, 117, 114, 114, 101, 110, 116, 84, 105, 109, 101, 0, 80, 254, 171, 112, 82, 1, 0, 0, 16, 99, 111, 111, 108, 51, 50, 98, 105, 116, 78, 117, 109, 98, 101, 114, 0, 41, 35, 0, 0, 18, 99, 111, 111, 108, 54, 52, 98, 105, 116, 78, 117, 109, 98, 101, 114, 0, 200, 167, 77, 246, 4, 0, 0, 0, 13, 99, 111, 100, 101, 0, 28, 0, 0, 0, 99, 111, 110, 115, 111, 108, 101, 46, 108, 111, 103, 40, 34, 72, 101, 108, 108, 111, 32, 116, 104, 101, 114, 101, 34, 41, 59, 0, 15, 99, 111, 100, 101, 87, 105, 116, 104, 83, 99, 111, 112, 101, 0, 56, 0, 0, 0, 28, 0, 0, 0, 99, 111, 110, 115, 111, 108, 101, 46, 108, 111, 103, 40, 34, 72, 101, 108, 108, 111, 32, 116, 104, 101, 114, 101, 34, 41, 59, 0, 20, 0, 0, 0, 2, 104, 101, 121, 0, 6, 0, 0, 0, 104, 101, 108, 108, 111, 0, 0, 10, 110, 111, 116, 104, 105, 110, 103, 0, 0]
        
        let kittenDocument: Document = [
            "doubleTest": 0.04,
            "stringTest": "foo",
            "documentTest": [
                "documentSubDoubleTest": 13.37,
                "subArray": ["henk", "fred", "kaas", "goudvis"]
            ],
            "nonRandomObjectId": try! ~ObjectId("0123456789ABCDEF01234567"),
            "currentTime": .dateTime(Date(timeIntervalSince1970: Double(1453589266))),
            "cool32bitNumber": .int32(9001),
            "cool64bitNumber": 21312153544,
            "code": .javascriptCode("console.log(\"Hello there\");"),
            "codeWithScope": .javascriptCodeWithScope(code: "console.log(\"Hello there\");", scope: ["hey": "hello"]),
            "nothing": .null
        ]
        
        XCTAssert(expected == kittenDocument.bytes)
        
        let dogUment = Document(data: kittenDocument.bytes)
        let dogUment2 = NSData(bytes: UnsafePointer<[UInt8]>(expected), length: expected.count)
        
        let dogUment3 = Document(data: dogUment2)
        
        XCTAssert(dogUment.bytes == kittenDocument.bytes)
        XCTAssert(dogUment.bytes == dogUment3.bytes)
        
        let documents = [Document](bsonBytes: [0x00])
        XCTAssertEqual(documents.count, 0)
        
        // {"cool32bitNumber":9001,"cool64bitNumber":{"$numberLong":"21312153544"},"currentTime":{"$date":"1970-01-17T19:46:29.266Z"},"documentTest":{"documentSubDoubleTest":13.37,"subArray":{"0":"henk","1":"fred","2":"kaas","3":"goudvis"}},"doubleTest":0.04,"nonRandomObjectId":{"$oid":"0123456789abcdef01234567"},"nothing":null,"stringTest":"foo"}
        
        var expected2 : [UInt8] = [0x31, 0x00, 0x00, 0x00, 0x04]
        expected2 += "BSON".cStringBytes
        expected2 += [0x00, 0x26, 0x00, 0x00, 0x00, 0x02, 0x30, 0x00, 0x08, 0x00, 0x00, 0x00]
        expected2 += "awesome".bytes
        expected2 += [0x00, 0x01, 0x31, 0x00, 0x33, 0x33, 0x33, 0x33, 0x33, 0x33, 0x14, 0x40, 0x10, 0x32, 0x00, 0xc2, 0x07, 0x00, 0x00, 0x00, 0x00]
        
        var nullAsElementType = expected2
        nullAsElementType[4] = 0x00
        
        var unexpectedElementType = expected2
        unexpectedElementType[4] = 0x23
        
        let bsonCStringData = "BSON".cStringBytes
        let halloStringData = "Hallo".bytes
        
        var missingNullTerminator : [UInt8] = Int32(13).bytes
        missingNullTerminator += [0x04]
        missingNullTerminator += Array(bsonCStringData[0..<(bsonCStringData.count - 1)])
        missingNullTerminator += [0x02]
        missingNullTerminator += Array(halloStringData[0..<(halloStringData.count - 1)])
        missingNullTerminator += [0x00]
        
        // TODO: Missing tests for ParseError. No null terminators
    }
    
    func testDocumentSequenceType() {
        var kittenDocument: Document = [
            "doubleTest": 0.04,
            "stringTest": "foo",
            "documentTest": [
                "documentSubDoubleTest": 13.37,
                "subArray": ["henk", "fred", "kaas", "goudvis"]
            ],
            "nonRandomObjectId": try! ~ObjectId("0123456789ABCDEF01234567"),
            "currentTime": ~Date(timeIntervalSince1970: Double(1453589266)),
            "cool32bitNumber": .int32(9001),
            "cool64bitNumber": 21312153544,
            "code": .javascriptCode("console.log(\"Hello there\");"),
            "codeWithScope": .javascriptCodeWithScope(code: "console.log(\"Hello there\");", scope: ["hey": "hello"]),
            "nothing": .null
        ]
        
        let arrayThingy: Document = [
            "a", "b", 3, true, "kaas", "a"
        ]
        
        XCTAssert(arrayThingy[0].stringValue == "a")
        XCTAssert(arrayThingy[3].boolValue == true)
        
        XCTAssert(kittenDocument["doubleTest"].doubleValue == 0.04)
        kittenDocument["doubleTest"] = "hoi"
        XCTAssert(kittenDocument["doubleTest"].stringValue == "hoi")
//        XCTAssert(kittenDocument[kittenDocument.index(forKey: "doubleTest")!].stringValue == "hoi")
        
//        kittenDocument.updateValue("doubleTest", forKey: "doubleTest")
//        XCTAssert(kittenDocument[kittenDocument.index(forKey: "doubleTest")!].stringValue == "doubleTest")
        
//        let oldValue = kittenDocument.remove(at: kittenDocument.startIndex)
//        XCTAssert(oldValue.1.bytes != kittenDocument[kittenDocument.startIndex].bytes)
        
//        kittenDocument.removeAll()
//        XCTAssert(kittenDocument.isEmpty)
    }
    
    func testDeserializationPerformance() {
        #if !os(Linux)
            let kittenDocument: Document = [
                                               "doubleTest": 0.04,
                                               "stringTest": "foo",
                                               "documentTest": [
                                                                   "documentSubDoubleTest": 13.37,
                                                                   "subArray": ["henk", "fred", "kaas", "goudvis"]
                ],
                                               "nonRandomObjectId": try! ~ObjectId("0123456789ABCDEF01234567"),
                                               "currentTime": ~Date(timeIntervalSince1970: Double(1453589266)),
                                               "cool32bitNumber": .int32(9001),
                                               "cool64bitNumber": 21312153544,
                                               "code": .javascriptCode("console.log(\"Hello there\");"),
                                               "codeWithScope": .javascriptCodeWithScope(code: "console.log(\"Hello there\");", scope: ["hey": "hello"]),
                                               "nothing": .null
            ]
            
            let bytes = kittenDocument.bytes
            
            measure {
                for _ in 0..<1000 {
                    // TODO: make this not optimized out
                    let _ = Document(data: bytes)
                }
            }
        #endif
    }
    
    func testSerializationPerformance() {
        #if !os(Linux)
            let kittenDocument: Document = [
                                               "doubleTest": 0.04,
                                               "stringTest": "foo",
                                               "documentTest": [
                                                                   "documentSubDoubleTest": 13.37,
                                                                   "subArray": ["henk", "fred", "kaas", "goudvis"]
                ],
                                               "nonRandomObjectId": try! ~ObjectId("0123456789ABCDEF01234567"),
                                               "currentTime": ~Date(timeIntervalSince1970: Double(1453589266)),
                                               "cool32bitNumber": .int32(9001),
                                               "cool64bitNumber": 21312153544,
                                               "code": .javascriptCode("console.log(\"Hello there\");"),
                                               "codeWithScope": .javascriptCodeWithScope(code: "console.log(\"Hello there\");", scope: ["hey": "hello"]),
                                               "nothing": .null
            ]
            
            measure {
                for _ in 0..<1000 {
                    let _ = kittenDocument.bytes
                }
            }
        #endif
    }
    
//    func testFullDocumentPerformance() {
//        let data = NSData.init(contentsOfFile: "/Users/joannis/Documents/Performance/dump/tikcit/registrations.bson")!
//        
//        let count = data.length / sizeof(UInt8)
//        
//        
//        var bytesArray = [UInt8](repeating: 0, count: count)
//        data.getBytes(&bytesArray, length:count * sizeof(UInt8))
//        
//        let documents = [Document](bsonBytes: bytesArray)
//        
//        measure {
//            var data = 0
//            var doc = 0
//            
//            for document in documents {
//                for (k, v) in document {
//                    data += v.bytes.count - k.bytes.count
//                }
//                doc += 1
//            }
//            
//            print(doc)
//            print(data)
//        }
//    }
//    
//    func testSubscriptPerformance() {
//        let data = NSData.init(contentsOfFile: "/Users/joannis/Documents/Performance/dump/tikcit/registrations.bson")!
//        
//        let count = data.length / sizeof(UInt8)
//        var bytesArray = [UInt8](repeating: 0, count: count)
//        data.getBytes(&bytesArray, length:count * sizeof(UInt8))
//        
//        let documents = [Document](bsonBytes: bytesArray)
//        
//        let k = "_id"
//        
//        measure {
//            var data = [UInt8]()
//            
//            for document in documents {
//                data.append(document[k].bytes[0])
//            }
//            
//            print(data.count)
//        }
//    }
}
