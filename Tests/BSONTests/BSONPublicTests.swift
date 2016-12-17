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

final class BSONPublicTests: XCTestCase {
    
    static var allTests : [(String, (BSONPublicTests) -> () throws -> Void)] {
        return [
            ("testDictionaryLiteral", testDictionaryLiteral),
            ("testDocumentCollectionFunctionality", testDocumentCollectionFunctionality),
            ("testInitializedFromData", testInitializedFromData),
            ("testArrayRelatedFunctions", testArrayRelatedFunctions),
            ("testMultipleDocumentsInitialization", testMultipleDocumentsInitialization),
            ("testInitFromFoundationData", testInitFromFoundationData),
            ("testSerialization", testSerialization),
            ("testValidation", testValidation),
            ("testSubscripting", testSubscripting),
            ("testObjectId", testObjectId),
            ("testExtendedJSON", testExtendedJSON),
            ("testDocumentIndexes", testDocumentIndexes),
            ("testComparison", testComparison),
            ("testDotSyntax", testDotSyntax),
            ("testJSONEscapeSequences", testJSONEscapeSequences),
            ("testDocumentCombineOperators", testDocumentCombineOperators),
            ("testDocumentFlattening", testDocumentFlattening),
            ("testTypeChecking", testTypeChecking),
            ("testExtraction", testExtraction)
        ]
    }
    
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
        "cool64bitNumber": 21312153,
        "code": .javascriptCode("console.log(\"Hello there\");"),
        "codeWithScope": .javascriptCodeWithScope(code: "console.log(\"Hello there\");", scope: ["hey": "hello"]),
        "nothing": .null,
        "data": .binary(subtype: BinarySubtype.generic, data: [34,34,34,34,34]),
        "boolFalse": false,
        "boolTrue": true,
        "timestamp": .timestamp(stamp: 2000, increment: 8),
        "regex": .regularExpression(pattern: "[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}", options: "b"),
        "minKey": .minKey,
        "maxKey": .maxKey
    ]
    
    func validateAgainstKitten(_ document: Document) {
        XCTAssertEqual(document.count, 17) //yes, hardcoded!
        XCTAssertEqual(document.bytes, kittenDocument.bytes)
        
        for key in kittenDocument.keys {
            XCTAssertEqual(kittenDocument[key], document[key])
        }
    }
    
    func testDictionaryLiteral() {
        XCTAssertEqual(kittenDocument["doubleTest"], Value.double(0.04))
        XCTAssertEqual(kittenDocument["nonRandomObjectId"], try! ~ObjectId("0123456789ABCDEF01234567"))
    }
    
    func testDocumentCollectionFunctionality() {
        var document = kittenDocument
        
        XCTAssertEqual(document.removeValue(forKey: "stringTest"), "foo")
        XCTAssertEqual(document["stringTest"], .nothing)
        XCTAssertEqual(document.removeValue(forKey: "stringTest"), nil)
        
        XCTAssertEqual(document.keys, ["doubleTest", "documentTest", "nonRandomObjectId", "currentTime", "cool32bitNumber", "cool64bitNumber", "code", "codeWithScope", "nothing", "data", "boolFalse", "boolTrue", "timestamp", "regex", "minKey", "maxKey"])
        
        let kittenDictionary = kittenDocument.dictionaryValue
        
        for (k, v) in kittenDictionary {
            XCTAssertEqual(kittenDocument[k], v)
        }
    }
    
    func testObjectIdUniqueness() {
        var oids = [String]()
        
        for _ in 0..<1000 {
            let oid = ObjectId().hexString
            
            XCTAssertFalse(oids.contains(oid))
            oids.append(oid)
        }
    }
    
    func testAppendingContents() {
        var doc = [1, 2, 3, 4, 5] as Document
        doc.append(contentsOf: [6, 7, 8, 9, 10])
        
        XCTAssertEqual(doc, [1, 2, 3, 4, 5, 6, 7, 8, 9, 10])
        
        var dictionaryDoc = [
            "henk": 2,
            "bob": 3
        ] as Document
        
        dictionaryDoc.append(contentsOf: [
                "henk": 1,
                "fred": true
            ])
        
        XCTAssertEqual(dictionaryDoc, [
                "henk": 1,
                "bob": 3,
                "fred": true
            ])
    }
    
    func testInitializedFromData() {
        let document = Document(data: [121, 1, 0, 0, 1, 100, 111, 117, 98, 108, 101, 84, 101, 115, 116, 0, 123, 20, 174, 71, 225, 122, 164, 63, 2, 115, 116, 114, 105, 110, 103, 84, 101, 115, 116, 0, 4, 0, 0, 0, 102, 111, 111, 0, 3, 100, 111, 99, 117, 109, 101, 110, 116, 84, 101, 115, 116, 0, 102, 0, 0, 0, 1, 100, 111, 99, 117, 109, 101, 110, 116, 83, 117, 98, 68, 111, 117, 98, 108, 101, 84, 101, 115, 116, 0, 61, 10, 215, 163, 112, 189, 42, 64, 4, 115, 117, 98, 65, 114, 114, 97, 121, 0, 56, 0, 0, 0, 2, 48, 0, 5, 0, 0, 0, 104, 101, 110, 107, 0, 2, 49, 0, 5, 0, 0, 0, 102, 114, 101, 100, 0, 2, 50, 0, 5, 0, 0, 0, 107, 97, 97, 115, 0, 2, 51, 0, 8, 0, 0, 0, 103, 111, 117, 100, 118, 105, 115, 0, 0, 0, 7, 110, 111, 110, 82, 97, 110, 100, 111, 109, 79, 98, 106, 101, 99, 116, 73, 100, 0, 1, 35, 69, 103, 137, 171, 205, 239, 1, 35, 69, 103, 9, 99, 117, 114, 114, 101, 110, 116, 84, 105, 109, 101, 0, 80, 254, 171, 112, 82, 1, 0, 0, 16, 99, 111, 111, 108, 51, 50, 98, 105, 116, 78, 117, 109, 98, 101, 114, 0, 41, 35, 0, 0, 18, 99, 111, 111, 108, 54, 52, 98, 105, 116, 78, 117, 109, 98, 101, 114, 0, 200, 167, 77, 246, 4, 0, 0, 0, 13, 99, 111, 100, 101, 0, 28, 0, 0, 0, 99, 111, 110, 115, 111, 108, 101, 46, 108, 111, 103, 40, 34, 72, 101, 108, 108, 111, 32, 116, 104, 101, 114, 101, 34, 41, 59, 0, 15, 99, 111, 100, 101, 87, 105, 116, 104, 83, 99, 111, 112, 101, 0, 56, 0, 0, 0, 28, 0, 0, 0, 99, 111, 110, 115, 111, 108, 101, 46, 108, 111, 103, 40, 34, 72, 101, 108, 108, 111, 32, 116, 104, 101, 114, 101, 34, 41, 59, 0, 20, 0, 0, 0, 2, 104, 101, 121, 0, 6, 0, 0, 0, 104, 101, 108, 108, 111, 0, 0, 10, 110, 111, 116, 104, 105, 110, 103, 0, 0])
        
        // {"cool32bitNumber":9001,"cool64bitNumber":{"$numberLong":"21312153544"},"currentTime":{"$date":"1970-01-17T19:46:29.266Z"},"documentTest":{"documentSubDoubleTest":13.37,"subArray":{"0":"henk","1":"fred","2":"kaas","3":"goudvis"}},"doubleTest":0.04,"nonRandomObjectId":{"$oid":"0123456789abcdef01234567"},"nothing":null,"stringTest":"foo"}
        
        XCTAssertEqual(document["cool32bitNumber"], Value.int32(9001))
        XCTAssertEqual(document["cool64bitNumber"], Value.int64(21312153544))
        XCTAssertEqual(document["documentTest"]["documentSubDoubleTest"], Value.double(13.37))
        XCTAssertEqual(document["documentTest"]["subArray"][1], Value.string("fred"))
        XCTAssertEqual(document["doubleTest"], Value.double(0.04))
        XCTAssertEqual(document["nothing"], Value.null)
        XCTAssertEqual(document["nonexistentkey"], Value.nothing)
        XCTAssertEqual(document["stringTest"], Value.string("foo"))
    }
    
    func testArrayRelatedFunctions() {
        let document: Document = ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z"]
        XCTAssertTrue(document.validatesAsArray())
        XCTAssertEqual(document.count, 26)
        
        let date = Date()
        let arrayDoc: Document = ["kaas", "sap", "saus", 55, "fred", ["subDocument": true], 44.3, ~date]
        
        XCTAssertTrue(arrayDoc.validatesAsArray())
        
        let bytes = arrayDoc.bytes
        let reInstantiated = Document(data: bytes)
        
        let arrayValue = reInstantiated.arrayValue
        
        XCTAssertEqual(arrayDoc.count, arrayValue.count)
        XCTAssertEqual(arrayValue[0], Value.string("kaas"))
        
        let arrayJSON = reInstantiated.makeExtendedJSON()
        
        XCTAssertTrue(arrayJSON.hasPrefix("["))
        XCTAssertTrue(arrayJSON.hasSuffix("]"))
        
        let anArray: Document = ["0": "hoi", "1": "kaas", "2": "fred"]
        XCTAssertTrue(anArray.validatesAsArray())
        XCTAssertFalse(kittenDocument.validatesAsArray())
        
        // BSON specifies that arrays should be stored in the correct sequence
        let notAnArray: Document = ["0": "kaas", "3": "fred", "2": "hoi", "1": 4]
        XCTAssertFalse(notAnArray.validatesAsArray())
        
        
        var array: Document = [.int32(0), .int32(1), .int32(2), .int32(3), .int32(4)]
        array[1] = .string("hello")
        
        XCTAssertEqual(array[0], .int32(0))
        XCTAssertNotEqual(array[1], .int32(1))
        XCTAssertEqual(array[1], .string("hello"))
        XCTAssertEqual(array[2], .int32(2))
        XCTAssertEqual(array[3], .int32(3))
        XCTAssertEqual(array[4], .int32(4))
    }
    
    func testMultipleDocumentsInitialization() {
        let doc1: Document = ["kaas", "sap", "saus"]
        let doc2 = kittenDocument
        let doc3: Document = ["hoi": "test", "3": 24]
        
        let data = doc1.bytes + doc2.bytes + doc3.bytes
        
        let singleDoc = Document(data: data)
        XCTAssertEqual(singleDoc.bytes, doc1.bytes)
        
        let multipleDocs = [Document](bsonBytes: data)
        XCTAssertEqual(multipleDocs.count, 3)
        XCTAssertEqual(multipleDocs[0].bytes, doc1.bytes)
        XCTAssertEqual(multipleDocs[1].bytes, doc2.bytes)
        XCTAssertEqual(multipleDocs[2].bytes, doc3.bytes)
         
        validateAgainstKitten(multipleDocs[1])
    }
    
    func testInitFromFoundationData() {
        let data = Data(bytes: kittenDocument.bytes)
        let document = Document(data: data)
        XCTAssertEqual(document.bytes, kittenDocument.bytes)
    }
    
    func testSerialization() {
        let originalBinary: [UInt8] = [5,0,0,0,0,5,0,0,0,0]
        
        let documents = [Document](bsonBytes: originalBinary)
        
        XCTAssertEqual(documents.count, 2)
        XCTAssertEqual(documents.bytes, originalBinary)
        
        XCTAssertEqual(documents[0].byteCount, 5)
        XCTAssertEqual(documents[0].bytes, [5,0,0,0,0])
    }
    
    func testValidation() {
        XCTAssertTrue(kittenDocument.validate())
        XCTAssertFalse(Document(data: [0,0,0,0,0]).validate())
        XCTAssertFalse(Document(data: [4,0,4,0,6,4,32,43,3,2,2,5,6,63]).validate())
        
        let documents0 = [Document](bsonBytes: [5,0,0,0,0,0,0,0,0,0])
        let documents1 = [Document](bsonBytes: [5,0,0,0,0,6,0,0,0,0])
        
        XCTAssertEqual(documents0.count, 1)
        XCTAssertEqual(documents1.count, 1)
        
        let documentsBytes = kittenDocument.bytes + [9,0,0,0,1,40,0,20,0]
        
        let containsInvalidDocument = [Document](bsonBytes: documentsBytes)
        let containsValidDocuments = [Document](bsonBytes: documentsBytes, validating: true)
        
        XCTAssertEqual(containsInvalidDocument.count, 2)
        XCTAssertEqual(containsValidDocuments.count, 1)
        
        let invalidTypeDocument = Document(data: [16,0,0,0,80,40,40,40,40,40,0,6,0,0,0,0,40,40,40,40,40,0,0])
        
        for _ in invalidTypeDocument {
            XCTFail()
        }
    }
    
    func testSubscripting() {
        var document = kittenDocument
        XCTAssertEqual(document["stringTest"], ~"foo")
        XCTAssertEqual(document[1], ~"foo")
        XCTAssertEqual(document["documentTest"][0], document["documentTest"]["documentSubDoubleTest"])
        XCTAssertEqual(document["documentTest"][0], ~13.37)
        
        XCTAssertEqual(document[3], try! ~ObjectId("0123456789ABCDEF01234567"))
        
        document[3] = try! ~ObjectId("0123456789ABCDEF0123456A")
    
        XCTAssertEqual(document[3], try! ~ObjectId("0123456789ABCDEF0123456A"))
        
        XCTAssertEqual(document[document.count], .nothing)
        
        document["minKey"] = "kittens"
        XCTAssertEqual(document["minKey"], "kittens")
        
        XCTAssertEqual(kittenDocument["documentTest", "subArray"][0].string, "henk")
        
        let recursiveDocument: Document = [
            "henk": [
                "fred": [
                    "bob": [
                        "piet": [
                            "klaas": 3
                        ]
                    ]
                ]
            ]
        ]
        
        XCTAssertEqual(recursiveDocument["henk"]["fred", "bob", "piet"]["klaas"].int, 3)
    }
    
    func testObjectId() throws {
        let random = ObjectId()
        
        let hs = "AFAAABACADAEA0A1A2A3A4A2"
        let fromHex = try ObjectId(hs)
        
        XCTAssertEqual(fromHex.storage.0, 0xAF)
        XCTAssertEqual(fromHex.storage.1, 0xAA)
        XCTAssertEqual(fromHex.storage.2, 0xAB)
        XCTAssertEqual(fromHex.storage.3, 0xAC)
        XCTAssertEqual(fromHex.storage.4, 0xAD)
        XCTAssertEqual(fromHex.storage.5, 0xAE)
        XCTAssertEqual(fromHex.storage.6, 0xA0)
        XCTAssertEqual(fromHex.storage.7, 0xA1)
        XCTAssertEqual(fromHex.storage.8, 0xA2)
        XCTAssertEqual(fromHex.storage.9, 0xA3)
        XCTAssertEqual(fromHex.storage.10, 0xA4)
        XCTAssertEqual(fromHex.storage.11, 0xA2)
        
        XCTAssertNotEqual(random.hexString, fromHex.hexString)
        XCTAssertEqual(fromHex.hexString, hs.lowercased())
        
        var toMutate = ObjectId()
        toMutate.storage = random.storage
        XCTAssertEqual(toMutate.hexString, random.hexString)
        
        // random should not be the same
        XCTAssertNotEqual(ObjectId()._storage, ObjectId()._storage)
        
        let other = ObjectId(raw: random.storage)
        XCTAssertEqual(random.hexString, other.hexString)
        
        // Wrong initialization string length:
        XCTAssertThrowsError(try ObjectId("1234567890"))
        
        // Wrong initialization data length:
        XCTAssertThrowsError(try ObjectId(bytes: [0,1,2,3]))
        
        // Wrong initialization string:
        XCTAssertThrowsError(try ObjectId("kaaskaaskaaskaaskaaskaas"))
    }
    
    func testExtendedJSON() throws {
        
        let simpleJson = "{\"kaas\":       4.2}"
        let simpleDocument = try Document(extendedJSON: simpleJson)
        XCTAssertEqual(simpleDocument["kaas"], ~4.2)
        
        
        let kittenJSON = kittenDocument.makeExtendedJSON()
        
        let otherDocument = try Document(extendedJSON: kittenJSON)
        
        XCTAssertEqual(kittenDocument, otherDocument)
        
        XCTAssertEqual(Value.nothing.makeExtendedJSON(), "{\"$undefined\":true}")
    }
    
    func testDocumentIndexes() {
        let firstKittenKV = kittenDocument[kittenDocument.startIndex]
        let lastKittenKV = kittenDocument[kittenDocument.endIndex]
        
        XCTAssertEqual(firstKittenKV.key, "doubleTest")
        XCTAssertEqual(firstKittenKV.value, 0.04)
        
        XCTAssertEqual(lastKittenKV.key, "maxKey")
        XCTAssertEqual(lastKittenKV.value, .maxKey)
        
        var document = kittenDocument
        
        document[document.endIndex] = (key: "bob", value: 3.14)
        let lastElement = document[document.endIndex]
        
        XCTAssertEqual(lastElement.key, "bob")
        XCTAssertEqual(lastElement.value, 3.14)
        
        XCTAssert(document.startIndex < document.endIndex)
        XCTAssertFalse(document.endIndex < document.startIndex)
        XCTAssertEqual(document.startIndex, document.startIndex)
        
        let secondIndex = kittenDocument.index(after: kittenDocument.startIndex)
        XCTAssertEqual(kittenDocument[secondIndex].key, "stringTest")
    }
    
    func testComparison() {
        XCTAssert(kittenDocument["doubleTest"] == 0.04)
        XCTAssert(kittenDocument["stringTest"] == "foo")
        
        let documentTest = [
            "documentSubDoubleTest": 13.37,
            "subArray": ["henk", "fred", "kaas", "goudvis"]
            ] as Document
        
        XCTAssert(kittenDocument["documentTest"] == documentTest)
        
        let nonRandomObjectId = try! ObjectId("0123456789ABCDEF01234567")
        XCTAssert(kittenDocument["nonRandomObjectId"] == nonRandomObjectId)
        XCTAssert(try! ObjectId("0123456789ABCDEF01234567") == nonRandomObjectId)
        XCTAssert(nonRandomObjectId == "0123456789ABCDEF01234567")
        
        XCTAssert(kittenDocument["currentTime"] == Date(timeIntervalSince1970: Double(1453589266)))
        XCTAssert(kittenDocument["cool32bitNumber"] == 9001)
        XCTAssert(kittenDocument["cool64bitNumber"] == 21312153)
        XCTAssert(kittenDocument["code"] == .javascriptCode("console.log(\"Hello there\");"))
        XCTAssert(kittenDocument["nothing"] == .null)
        XCTAssert(kittenDocument["boolFalse"] == false)
        XCTAssert(kittenDocument["boolTrue"] == true)
        
        let bytes: [UInt8] = [34,34,34,34,34]
        XCTAssert(kittenDocument["data"] == bytes)
        
        XCTAssert(kittenDocument["timestamp"] == .timestamp(stamp: 2000, increment: 8))
        XCTAssert(kittenDocument["regex"] == .regularExpression(pattern: "[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}", options: "b"))
        XCTAssert(kittenDocument["minKey"] == .minKey)
        XCTAssert(kittenDocument["maxKey"] == .maxKey)
        
        let emptyDocument = Document()
        
        XCTAssertNotEqual(~emptyDocument, .nothing)
        XCTAssertNotEqual(~emptyDocument, .array([]))
        XCTAssertEqual(~emptyDocument, .document([:]))
        XCTAssertNotEqual([:] as Document, [] as Document)
        XCTAssertEqual([:] as Document, [:] as Document)
        XCTAssertEqual([] as Document, [] as Document)
        
    }
    
    func testDotSyntax() {
        var d = kittenDocument
        let v = "harriebob"
        
        d["kaassapsaus.freddelien"] = ~v
        d["hont.kad.varkun.konein"] = ~v
        
        XCTAssert(d["kaassapsaus"]["freddelien"] == v)
        XCTAssert(d["kaassapsaus.freddelien"] == v)
        XCTAssert(d["documentTest.documentSubDoubleTest"] == 13.37)
        
        XCTAssert(d["hont.kad.varkun.konein"] == v)
        XCTAssert(d["hont"]["kad"]["varkun"]["konein"] == v)
    }
    
    func testJSONEscapeSequences() {
        let bson: Document = ["hello": "\"fred\n\n\n\t😂", "kaas": "\r\u{c}\u{8}"]
        let json = bson.makeExtendedJSON()
        
        XCTAssertEqual(try Document(extendedJSON: json).bytes, bson.bytes)
    }
    
    func testDocumentCombineOperators() {
        let stillJustKittenDocument = kittenDocument + kittenDocument
        validateAgainstKitten(stillJustKittenDocument)
        
        let doc1 = ["harrie": "bob", "is": 4, "konijn": true] as Document
        let doc2 = ["vis": "kaas", "konijn": "nee", "henk": false] as Document
        let doc3 = doc1 + doc2
        XCTAssertEqual(doc3, ["harrie": "bob", "is": 4, "vis": "kaas", "konijn": "nee", "henk": false])
        
    }
    
    func testDocumentFlattening() {
        let correctFlatKitten: Document = [
            "doubleTest": 0.04,
            "stringTest": "foo",
            "documentTest.documentSubDoubleTest": 13.37,
            "documentTest.subArray.0": "henk",
            "documentTest.subArray.1": "fred",
            "documentTest.subArray.2": "kaas",
            "documentTest.subArray.3": "goudvis",
            "nonRandomObjectId": try! ~ObjectId("0123456789ABCDEF01234567"),
            "currentTime": .dateTime(Date(timeIntervalSince1970: Double(1453589266))),
            "cool32bitNumber": .int32(9001),
            "cool64bitNumber": 21312153,
            "code": .javascriptCode("console.log(\"Hello there\");"),
            "codeWithScope": .javascriptCodeWithScope(code: "console.log(\"Hello there\");", scope: ["hey": "hello"]),
            "nothing": .null,
            "data": .binary(subtype: BinarySubtype.generic, data: [34,34,34,34,34]),
            "boolFalse": false,
            "boolTrue": true,
            "timestamp": .timestamp(stamp: 2000, increment: 8),
            "regex": .regularExpression(pattern: "[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}", options: "b"),
            "minKey": .minKey,
            "maxKey": .maxKey
        ]
        
        var flattenedKitten = kittenDocument
        flattenedKitten.flatten()
        
        XCTAssertEqual(correctFlatKitten, flattenedKitten)
        XCTAssertTrue(flattenedKitten.validate())
        
    }
    
    func testTypeChecking() {
        XCTAssertEqual(kittenDocument.type(at: 0), .double)
        XCTAssertEqual(kittenDocument.type(at: 1), .string)
        XCTAssertEqual(kittenDocument.type(at: 2), .document)
        XCTAssertEqual(kittenDocument.type(at: -1), nil)
        XCTAssertEqual(kittenDocument.type(at: 25), nil)
        XCTAssertEqual(kittenDocument.type(at: kittenDocument.count + 1), nil)
        
        XCTAssertEqual(kittenDocument.type(at: "doubleTest"), .double)
        XCTAssertEqual(kittenDocument.type(at: "stringTest"), .string)
        XCTAssertEqual(kittenDocument.type(at: "documentTest"), .document)
        XCTAssertEqual(kittenDocument["documentTest"].documentValue?.type(at: "subArray"), .arrayDocument)
        XCTAssertEqual(kittenDocument.type(at: "nonRandomObjectId"), .objectId)
        XCTAssertEqual(kittenDocument.type(at: "bob"), nil)
        XCTAssertEqual(kittenDocument.type(at: "piet"), nil)
        XCTAssertEqual(kittenDocument.type(at: "kenk"), nil)
    }
    
    func testExtraction() {
        let objectId = kittenDocument.extract("nonRandomObjectId") as ObjectId?
        let realObjectId = try? ObjectId("0123456789ABCDEF01234567")
        
        XCTAssertNotNil(objectId)
        XCTAssertEqual(objectId, realObjectId)
        
        let nilObjectId = kittenDocument.extract("nonRandomObjectId") as Int32?
        XCTAssertNil(nilObjectId)
        
        let double = kittenDocument.extract("doubleTest") as Double?
        XCTAssertNotNil(double)
        XCTAssertEqual(double, 0.04)
        
        let string = kittenDocument.extract("stringTest") as String?
        XCTAssertNotNil(string)
        XCTAssertEqual(string, "foo")
        
        let subDocument = kittenDocument.extract("documentTest") as Document?
        XCTAssertNotNil(subDocument)
        
        let subDouble = subDocument?.extract("documentSubDoubleTest") as Double?
        XCTAssertNotNil(subDouble)
        XCTAssertEqual(subDouble, 13.37)
        
        let time = kittenDocument.extract("currentTime") as Date?
        XCTAssertNotNil(time)
        XCTAssertEqual(time, Date(timeIntervalSince1970: Double(1453589266)))
        
        let int32 = kittenDocument.extract("cool32bitNumber") as Int32?
        XCTAssertNotNil(int32)
        XCTAssertEqual(int32, 9001)
        
        let int64 = kittenDocument.extract("cool64bitNumber") as Int64?
        XCTAssertNotNil(int64)
        XCTAssertEqual(int64, 21312153)
        
        let code = kittenDocument.extract("code") as String?
        XCTAssertNotNil(code)
        XCTAssertEqual(code, "console.log(\"Hello there\");")
        
        let data = kittenDocument.extract("data") as Data?
        XCTAssertNotNil(data)
        XCTAssertEqual(data, Data(bytes: [34,34,34,34,34]))
        
        let boolFalse = kittenDocument.extract("boolFalse") as Bool?
        let boolTrue = kittenDocument.extract("boolTrue") as Bool?
        
        XCTAssertNotNil(boolTrue)
        XCTAssertNotNil(boolFalse)
        XCTAssertNotEqual(boolTrue, boolFalse)
        XCTAssertEqual(boolTrue, true)
        XCTAssertEqual(boolFalse, false)
        
        let regex = kittenDocument.extract("regex") as RegularExpression?
        XCTAssertNotNil(regex)
        XCTAssertEqual(regex?.pattern, "[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}")
        
        XCTAssertEqual(kittenDocument.extract("cool32bitNumber") as Int?, 9001)
        XCTAssertEqual(kittenDocument.extract("cool64bitNumber") as Int?, 21312153)
    }
    
    func testKeyDetection() {
        var myDoc: Document = ["balance_status": "Pending"]
        XCTAssertEqual(myDoc["balance_status"].string, "Pending")
        myDoc["balance"] = 50
        XCTAssertEqual(myDoc["balance"].int, 50)
    }
    
    func testRawCreation() {
        var doc: Document = [:]
        
        doc[["nestedThings.thing1"]] = [
            "$exists": true
        ]
        
        XCTAssertEqual(doc[["nestedThings.thing1.$exists"]], .nothing)
        XCTAssertEqual(doc[["nestedThings.thing1"]]["$exists"], true)
        XCTAssertEqual(doc["nestedThings"]["thing1"]["$exists"], .nothing)
    }
}
