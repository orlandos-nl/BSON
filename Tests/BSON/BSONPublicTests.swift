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

// TODO: Test boolean `false`
// TODO: Test validation of invalid documents
// TODO: Test DocumentIndex

class BSONPublicTests: XCTestCase {
    
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
        "nothing": .null,
        "data": .binary(subtype: BinarySubtype.generic, data: [34,34,34,34,34]),
        "boolFalse": false,
        "boolTrue": true,
        "timestamp": .timestamp(stamp: 2000, increment: 8)
    ]
    
    func validateAgainstKitten(_ document: Document) {
        XCTAssertEqual(document.count, kittenDocument.count)
        XCTAssertEqual(document.bytes, kittenDocument.bytes)
        
        for key in kittenDocument.keys {
            XCTAssertEqual(kittenDocument[key], document[key])
        }
    }
    
    func testDictionaryLiteral() {
        XCTAssertEqual(kittenDocument["doubleTest"], Value.double(0.04))
        XCTAssertEqual(kittenDocument["nonRandomObjectId"], try! ~ObjectId("0123456789ABCDEF01234567"))
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
        
        // TODO: Test inserting values, inserting values halfway
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
    
    func testValidation() {
        XCTAssertTrue(kittenDocument.validate())
        XCTAssertFalse(Document(data: [0,0,0,0,0]).validate())
        XCTAssertFalse(Document(data: [4,0,4,0,6,4,32,43,3,2,2,5,6,63]).validate())
    }
    
    func testSubscripting() {
        var document = kittenDocument
        XCTAssertEqual(document["stringTest"], ~"foo")
        XCTAssertEqual(document[1], ~"foo")
        XCTAssertEqual(document["documentTest"][0], document["documentTest"]["documentSubDoubleTest"])
        XCTAssertEqual(document["documentTest"][0], ~13.37)
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
        
        let simpleJson = "{\"kaas\": 4.2}"
        let simpleDocument = try Document(extendedJSON: simpleJson)
        XCTAssertEqual(simpleDocument["kaas"], ~4.2)
        
        
        let kittenJSON = kittenDocument.makeExtendedJSON()
        
        let otherDocument = try Document(extendedJSON: kittenJSON)
        
        XCTAssertEqual(kittenDocument, otherDocument)
    }
    
    func testJSONEscapeSequences() {
        let bson: Document = ["hello": "\"fred\n\n\n\t😂", "kaas": "\r\u{c}\u{8}"]
        let json = bson.makeExtendedJSON()
        
        XCTAssertEqual(try Document(extendedJSON: json).bytes, bson.bytes)
    }
    
}
