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
            ("testDocumentLockup", testDocumentLockup),
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
            ("testObjectIdString", testObjectIdString),
            ("testObjectIdHash", testObjectIdHash ),
            ("testDocumentIndexes", testDocumentIndexes),
            ("testComparison", testComparison),
            ("testMultiSyntax", testMultiSyntax),
            ("testDocumentCombineOperators", testDocumentCombineOperators),
            ("testDocumentFlattening", testDocumentFlattening),
            ("testTypeChecking", testTypeChecking),
            ("testCacheCorruption", testCacheCorruption),
            ("testBinaryEquatable", testBinaryEquatable),
            ("testUsingDictionaryAsPrimitive", testUsingDictionaryAsPrimitive)
        ]
    }
    
    let kittenDocument: Document = [
        "doubleTest": 0.04,
        "stringTest": "foo",
        "documentTest": [
            "documentSubDoubleTest": 13.37,
            "subArray": ["henk", "fred", "kaas", "goudvis"] as Document
        ] as Document,
        "nonRandomObjectId": try! ObjectId("0123456789ABCDEF01234567"),
        "currentTime": Date(timeIntervalSince1970: Double(1453589266)),
        "cool32bitNumber": Int32(9001),
        "cool64bitNumber": 21312153,
        "code": JavascriptCode(code: "console.log(\"Hello there\");"),
        "codeWithScope": JavascriptCode(code: "console.log(\"Hello there\");", withScope: ["hey": "hello"]),
        "nothing": NSNull(),
        "data": Binary(data: [34,34,34,34,34], withSubtype: .generic),
        "boolFalse": false,
        "boolTrue": true,
        "timestamp": Timestamp(increment: 2000, timestamp: 8),
        "regex": RegularExpression(pattern: "[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}", options: []),
        "minKey": MinKey(),
        "maxKey": MaxKey()
    ]
    
    func testDocumentLockup() {
        var document = Document()
        document.removeValue(forKey: "_id")
        document["_id"] = "123"
        XCTAssertEqual(String(document["_id"]), "123")
        XCTAssertNotNil(document.dictionaryRepresentation["_id"])
        document.removeValue(forKey: "_id")
        XCTAssertEqual(String(document["_id"]), nil)
        XCTAssertNil(document.dictionaryRepresentation["_id"])
        document["_id"] = "456"
        XCTAssertEqual(String(document["_id"]), "456")
        XCTAssertNotNil(document.dictionaryRepresentation["_id"])
        document["anykey"] = "anyvalue"
        XCTAssertNotNil(document["anykey"] as? String)
        
        var document2 = Document()
        document2.removeValue(forKey: "anykey")
        document2["_id"] = "123"
        XCTAssertNotNil(document2["_id"])
        
        var document3 = Document()
        document3["_id"] = "123"
        XCTAssertEqual(String(document3.dictionaryRepresentation["_id"]), "123")
        document2.removeValue(forKey: "anykey")
        XCTAssertEqual(document3.dictionaryRepresentation["_id"] as? String, "123")
        XCTAssertNil(document3.dictionaryRepresentation["anykey"])
    }
    
    func testRelativeLength() {
        var document: Document = [
            "_id": ObjectId(),
            "henk": ["$db": "kaas", "$sap": "saus"]
        ]
        
        document["henk"] = ObjectId()
        XCTAssert(!document.validatesAsArray())
    }
    
    func testTrieCopy() {
        var doc = Document()
        doc["username"] = "bob"
        doc["password"] = "Secrat"
        
        var doc2 = doc
        
        let id = ObjectId()
        let id2 = ObjectId()
        
        doc["_id"] = id
        doc2["_id"] = id2
        
        XCTAssertEqual(ObjectId(doc["_id"]), id)
        XCTAssertEqual(ObjectId(doc2["_id"]), id2)
    }
    
    func testNullToNilInt() {
        var doc: Document = [
            "_id": NSNull(),
            "name": "Joannis",
            "email": "joannis@orlandos.nl"
        ]
        
        XCTAssert(doc.validate())
        XCTAssertEqual(doc.type(at: 0), .nullValue)
        
        doc[0] = nil
        
        XCTAssert(doc.validate())
        XCTAssertEqual(doc.type(at: 0), .string)
    }
    
    func testNullToNilString() {
        var doc: Document = [
            "_id": NSNull(),
            "name": "Joannis",
            "email": "joannis@orlandos.nl"
        ]
        
        XCTAssert(doc.validate())
        XCTAssertEqual(doc.type(at: "_id"), .nullValue)
        
        doc["_id"] = nil
        
        XCTAssert(doc.validate())
        XCTAssertEqual(doc.type(at: "_id"), nil)
    }
    
    func validateAgainstKitten(_ document: Document) {
        XCTAssertEqual(document.count, 17) //yes, hardcoded!
        XCTAssertEqual(document.bytes, kittenDocument.bytes)
    }
    
    func testDictionaryLiteral() {
        XCTAssertEqual(Double(kittenDocument["doubleTest"]), 0.04)
        XCTAssertEqual(ObjectId(kittenDocument["nonRandomObjectId"]), try! ObjectId("0123456789ABCDEF01234567"))
    }
    
    func testDocumentCollectionFunctionality() {
        var document = kittenDocument
        
        XCTAssert(document.validate())
        XCTAssertEqual(document.removeValue(forKey: "stringTest") as? String, "foo")
        XCTAssert(document.validate())
        XCTAssertEqual(String(document["stringTest"]), nil)
        XCTAssertEqual(String(document.removeValue(forKey: "stringTest")), nil)
       XCTAssert(document.validate())
        
        XCTAssertEqual(document.keys, ["doubleTest", "documentTest", "nonRandomObjectId", "currentTime", "cool32bitNumber", "cool64bitNumber", "code", "codeWithScope", "nothing", "data", "boolFalse", "boolTrue", "timestamp", "regex", "minKey", "maxKey"])
       XCTAssert(document.validate())
        
        XCTAssertEqual(document.dictionaryRepresentation.keys.sorted(), ["doubleTest", "documentTest", "nonRandomObjectId", "currentTime", "cool32bitNumber", "cool64bitNumber", "code", "codeWithScope", "nothing", "data", "boolFalse", "boolTrue", "timestamp", "regex", "minKey", "maxKey"].sorted())
    }
    
    func testObjectIdUniqueness() {
        var oids = [String]()
        oids.reserveCapacity(10_000)
        
        for _ in 0..<10_000 {
            let oid = ObjectId().hexString
            
            XCTAssertFalse(oids.contains(oid))
            oids.append(oid)
        }
    }
    
    func testInt() {
        let doc: Document = [
            "int32": Int32(1),
            "int64": (Int(Int32.max) + 5)
        ]
        
        XCTAssertEqual(doc.type(at: "int32"), .int32)
        XCTAssertEqual(doc.type(at: "int64"), .int64)
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
        
        XCTAssertEqual(Int32(document["cool32bitNumber"]), Int32(9001))
        XCTAssertEqual(Int(document["cool64bitNumber"]), 21312153544)
        XCTAssertEqual(Double(document["documentTest", "documentSubDoubleTest"]), 13.37)
        XCTAssertEqual(String(document["documentTest", "subArray", 1]), "fred")
        XCTAssertEqual(Double(document["doubleTest"]), 0.04)
        XCTAssert(document["nothing"] as? NSNull != nil)
        XCTAssertEqual(Document(document["nonexistentkey"]), nil)
        XCTAssertEqual(String(document["stringTest"]), "foo")
    }
    
    func testArrayRelatedFunctions() {
        let document: Document = ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z"]
        XCTAssertTrue(document.validatesAsArray())
        XCTAssertEqual(document.count, 26)
        
        let date = Date()
        let arrayDoc: Document = ["kaas", "sap", "saus", 55, "fred", ["subDocument": true] as Document, 44.3, date]
        
        XCTAssertTrue(arrayDoc.validatesAsArray())
        
        let bytes = arrayDoc.bytes
        let reInstantiated = Document(data: bytes)
        
        let arrayValue = reInstantiated.arrayRepresentation
        
        XCTAssertEqual(arrayDoc.count, arrayValue.count)
        XCTAssertEqual(arrayValue[0] as? String, "kaas")
        
        let anArray: Document = ["0": "hoi", "1": "kaas", "2": "fred"]
        XCTAssertFalse(anArray.validatesAsArray())
        XCTAssertFalse(kittenDocument.validatesAsArray())
        
        // TODO: BSON specifies that arrays should be stored in the correct sequence
        // We never had good support for this, so far. Make a github issue!
//        let notAnArray: Document = ["0": "kaas", "3": "fred", "2": "hoi", "1": 4]
//        XCTAssertFalse(notAnArray.validatesAsArray())
        
        
        var array: Document = [Int32(0), Int32(1), Int32(2), Int32(3), Int32(4)]
        array[1] = "hello"
        
        XCTAssertEqual(Int32(array[0]), Int32(0))
        XCTAssertNotEqual(Int32(array[1]), Int32(1))
        XCTAssertEqual(String(array[1]), "hello")
        XCTAssertEqual(Int32(array[2]), Int32(2))
        XCTAssertEqual(Int32(array[3]), Int32(3))
        XCTAssertEqual(Int32(array[4]), Int32(4))
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
//        XCTAssertFalse(Document(data: [0,0,0,0,0]).validate()) ??? todo?
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
    
    func testSubscripting() throws {
        var document = kittenDocument
        
        XCTAssertEqual(document[dotNotated: "documentTest.documentSubDoubleTest"] as? Double, 13.37)
        XCTAssertEqual(Double(document[0]), 0.04)
        XCTAssertEqual(String(document[2, 1, 2]), "kaas")
        XCTAssertEqual(String(document["documentTest", "subArray", 2]), "kaas")
        document["documentTest", "subArray", 2] = "hont"
        XCTAssertEqual(String(document["documentTest", "subArray", 2]), "hont")
        
        XCTAssertEqual(String(document["stringTest"]), "foo")
        XCTAssertEqual(String(document[1]), "foo")
        XCTAssertEqual(Double(document["documentTest", 0]), Double(document["documentTest", "documentSubDoubleTest"]))
        
        #if swift(>=3.1)
            XCTAssertEqual(Double(document["documentTest"][0]), 13.37)
        #endif
        
        XCTAssertEqual(ObjectId(document[3]), try ObjectId("0123456789ABCDEF01234567"))
        
        document[3] = try ObjectId("0123456789ABCDEF0123456A")
        
        XCTAssertEqual(ObjectId(document[3]), try ObjectId("0123456789ABCDEF0123456A"))
        
        document["minKey"] = "kittens"
        XCTAssertEqual(String(document["minKey"]), "kittens")
        
        #if swift(>=3.1)
            XCTAssertEqual(String(kittenDocument["documentTest", "subArray"][0]), "henk")
        #else
            XCTAssertEqual(String(Document(kittenDocument["documentTest", "subArray"])?[0]), "henk")
        #endif
        
        var recursiveDocument: Document = [
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
        
        #if swift(>=3.1)
            XCTAssertEqual(Int(recursiveDocument["henk"]["fred", "bob", "piet"]["klaas"]), 3)
            
            recursiveDocument["henk", "fred", "bob", "piet", "klaas"] = 4
            
            recursiveDocument["klaas", "piet", "bob", "fred", "henk"] = true
            
            XCTAssertEqual(Int(recursiveDocument["henk"]["fred", "bob", "piet"]["klaas"]), 4)
            
            XCTAssert(Bool(recursiveDocument["klaas", "piet", "bob", "fred", "henk"]) ?? false)
        #endif
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
        
        let timeId = ObjectId()
        
        XCTAssertLessThan(timeId.epoch.timeIntervalSinceNow, 2)
    }

    func testObjectIdString() throws {
        let stringId = try ObjectId("589488560239f4563ddc6ca0")
        XCTAssertEqual(stringId.epochSeconds, 1486129238)
        XCTAssertEqual(stringId.hexString, "589488560239f4563ddc6ca0")
        XCTAssertEqual(stringId.epoch.timeIntervalSince1970, 1486129238)
    }

    func testObjectIdHash() throws {
        let firstId = try ObjectId("589488560239f4563ddc6ca0")
        let secondId = try ObjectId("589488560239f4563ddc6ca0")
        let thirdId = try ObjectId("589488560239f4563ddc6cab")
        XCTAssertEqual(firstId.hashValue, secondId.hashValue)
        XCTAssertNotEqual(firstId.hashValue, thirdId.hashValue)
    }
    
    func testDocumentIndexes() {
        let firstKittenKV = kittenDocument[kittenDocument.startIndex]
        
        XCTAssertEqual(firstKittenKV.key, "doubleTest")
        XCTAssertEqual(firstKittenKV.value as? Double, 0.04)
        
        let document = kittenDocument
        
        XCTAssert(document.startIndex < document.endIndex)
        XCTAssertFalse(document.endIndex < document.startIndex)
        XCTAssertEqual(document.startIndex, document.startIndex)
        
        let secondIndex = kittenDocument.index(after: kittenDocument.startIndex)
        XCTAssertEqual(kittenDocument[secondIndex].key, "stringTest")
    }
    
    func testComparison() throws {
        XCTAssertEqual(Double(kittenDocument["doubleTest"]), 0.04)
        XCTAssertEqual(String(kittenDocument["stringTest"]), "foo")
        
        let documentTest = [
            "documentSubDoubleTest": 13.37,
            "subArray": ["henk", "fred", "kaas", "goudvis"]
            ] as Document
        
        XCTAssertEqual(Document(kittenDocument["documentTest"]), documentTest)
        
        let nonRandomObjectId = try ObjectId("0123456789ABCDEF01234567")
        XCTAssertEqual(ObjectId(kittenDocument["nonRandomObjectId"]), nonRandomObjectId)
        XCTAssertEqual(try ObjectId("0123456789ABCDEF01234567"), nonRandomObjectId)
        XCTAssertEqual(nonRandomObjectId.hexString.uppercased(), "0123456789ABCDEF01234567")
        
        XCTAssertEqual(Date(kittenDocument["currentTime"]), Date(timeIntervalSince1970: Double(1453589266)))
        XCTAssertEqual(Int32(kittenDocument["cool32bitNumber"]), 9001)
        XCTAssertEqual(Int(kittenDocument["cool64bitNumber"]), 21312153)
// FIXME:         XCTAssertEqual(JavascriptCode(kittenDocument["code"])?.code, "console.log(\"Hello there\");")
        XCTAssert(kittenDocument["nothing"] is NSNull)
        XCTAssertEqual(Bool(kittenDocument["boolFalse"]), false)
        XCTAssertEqual(Bool(kittenDocument["boolTrue"]), true)
        
        let bytes: [UInt8] = [34,34,34,34,34]
        XCTAssertEqual(Binary(kittenDocument["data"])?.makeBytes() ?? [], bytes)
        
        XCTAssertEqual(Timestamp(kittenDocument["timestamp"]), Timestamp(increment: 2000, timestamp: 8))
        XCTAssertEqual(RegularExpression(kittenDocument["regex"])?.pattern, "[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}")
        XCTAssert(kittenDocument["minKey"] is MinKey)
        XCTAssert(kittenDocument["maxKey"] is MaxKey)
        
        let emptyDocument = Document()
        
        XCTAssertNotEqual(emptyDocument, [])
        XCTAssertEqual(emptyDocument, [:])
        XCTAssertNotEqual([:] as Document, [] as Document)
        XCTAssertEqual([:] as Document, [:] as Document)
        XCTAssertEqual([] as Document, [] as Document)
        
    }
    
    func testMultiSyntax() {
        var d = kittenDocument
        let v = "harriebob"
        
        d["kaassapsaus", "freddelien"] = v
        d["hont", "kad", "varkun", "konein"] = v
        
        #if swift(>=3.1)
            XCTAssertEqual(String(d["kaassapsaus"]["freddelien"]), v)
        #endif
        
        XCTAssertEqual(String(d["kaassapsaus", "freddelien"]), v)
        XCTAssertEqual(Double(d["documentTest", "documentSubDoubleTest"]), 13.37)
        
        XCTAssertEqual(String(d["hont", "kad", "varkun", "konein"]), v)
        
        #if swift(>=3.1)
            XCTAssertEqual(String(d["hont"]["kad"]["varkun"]["konein"]), v)
        #endif
    }
    
    func testDocumentCombineOperators() {
        let stillJustKittenDocument = kittenDocument + kittenDocument
        validateAgainstKitten(stillJustKittenDocument)
        
        let doc1 = ["harrie": "bob", "is": 4, "konijn": true] as Document
        let doc2 = ["vis": "kaas", "konijn": "nee", "henk": false] as Document
        let doc3 = doc1 + doc2
        XCTAssertEqual(doc3, ["harrie": "bob", "is": 4, "vis": "kaas", "konijn": "nee", "henk": false])
        
    }
    
    // TODO: Fix this test, AssertEqual fails whilst the strins *are* equal
    func testDocumentFlattening() throws {
        let correctFlatKitten: Document = [
            "doubleTest": 0.04,
            "stringTest": "foo",
            "documentTest.documentSubDoubleTest": 13.37,
            "documentTest.subArray.0": "henk",
            "documentTest.subArray.1": "fred",
            "documentTest.subArray.2": "kaas",
            "documentTest.subArray.3": "goudvis",
            "nonRandomObjectId": try! ObjectId("0123456789ABCDEF01234567"),
            "currentTime": Date(timeIntervalSince1970: Double(1453589266)),
            "cool32bitNumber": Int32(9001),
            "cool64bitNumber": 21312153,
            "code": JavascriptCode(code: "console.log(\"Hello there\");"),
            "codeWithScope": JavascriptCode(code: "console.log(\"Hello there\");", withScope: ["hey": "hello"]),
            "nothing": NSNull(),
            "data": Binary(data: [34,34,34,34,34], withSubtype: .generic),
            "boolFalse": false,
            "boolTrue": true,
            "timestamp": Timestamp(increment: 2000, timestamp: 8),
            "regex": RegularExpression(pattern: "[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}", options: []),
            "minKey": MinKey(),
            "maxKey": MaxKey()
        ]
        
        var flattenedKitten = kittenDocument
        flattenedKitten.flatten()
        
        XCTAssertEqual(correctFlatKitten, flattenedKitten)
        XCTAssertTrue(flattenedKitten.validate())
    }
    
    func testKeyDetection() {
        var myDoc: Document = ["balance_status": "Pending"]
        XCTAssertEqual(String(myDoc["balance_status"]), "Pending")
        myDoc["balance"] = 50
        XCTAssertEqual(String(myDoc["balance_status"]), "Pending")
        XCTAssertEqual(Int32(myDoc["balance"]), 50)
        myDoc["balance_status"] = "Done"
        XCTAssertEqual(String(myDoc["balance_status"]), "Done")
        XCTAssertEqual(String(myDoc["balance"]), "50")
        
        let name = "coll"
        var command: Document = ["delete": name]
        let newDeletes = ["bob", 3, true] as [Primitive]
        
        command["deletes"] = Document(array: newDeletes)
        
        XCTAssertEqual(String(command["delete"]), name)
        XCTAssertEqual(Document(command["deletes"]), ["bob", 3, true])
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
        XCTAssertEqual((kittenDocument["documentTest"] as? Document)?.type(at: "subArray"), .arrayDocument)
        XCTAssertEqual(kittenDocument.type(at: "nonRandomObjectId"), .objectId)
        XCTAssertEqual(kittenDocument.type(at: "bob"), nil)
        XCTAssertEqual(kittenDocument.type(at: "piet"), nil)
        XCTAssertEqual(kittenDocument.type(at: "kenk"), nil)
    }
    
    func testCacheCorruption() {
        var document: Document = try! [
            "_id": ObjectId("5925985d7d6496b6f5346fc2"),
            "foo": Data(bytes: [UInt8](repeatElement(0, count: 100)))
        ]
        
        document["foo"] = nil
        _ = document["_id"] // did crash once
    }
    
    func testBinaryEquatable() {
        XCTAssert(Binary(data: Data(), withSubtype: .generic) == Binary(data: Data(), withSubtype: .generic))
        XCTAssertFalse(Binary(data: Data(), withSubtype: .generic) == Binary(data: Data(), withSubtype: .uuid))
        XCTAssertFalse(Binary(data: [0x00, 0x00], withSubtype: .generic) == Binary(data: Data(), withSubtype: .generic))
    }
    
    func testUsingDictionaryAsPrimitive() {
        let id = ObjectId()
        let dictionary1: [String: Int] = [
            "int": 5
        ]
        let dictionary2: [String: Primitive] = [
            "objectid": id,
            "int": 4
        ]
        let dictionary3: [String: Int?] = [
            "int": 5,
            "nil": nil
        ]
        let dictionary4: [String: Primitive?] = [
            "objectid": id,
            "int": 4,
            "nil": nil
        ]
        let document: Document = [
            "dictionary1": dictionary1,
            "dictionary2": dictionary2,
            "dictionary3": dictionary3,
            "dictionary4": dictionary4
        ]
        
        XCTAssertEqual(document["dictionary1", "int"] as? Int, 5)
        XCTAssertEqual(document["dictionary2", "objectid"] as? ObjectId, id)
        XCTAssertEqual(document["dictionary2", "int"] as? Int, 4)
        XCTAssertEqual(document["dictionary3", "int"] as? Int, 5)
        XCTAssertEqual(document["dictionary4", "objectid"] as? ObjectId, id)
        XCTAssertEqual(document["dictionary4", "int"] as? Int, 4)
    }
}
