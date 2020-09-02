//
//  BSONTests.swift
//  BSONTests
//
//  Created by Robbert Brandsma on 23-01-16.
//  Copyright © 2016 Robbert Brandsma. All rights reserved.
//

import NIO
import Foundation
import XCTest
import BSON

#if os(Linux)
    import Glibc
#endif

func assertValid(_ document: Document, file: StaticString = #filePath, line: UInt = #line) {
    let result = document.validate()
    guard result.isValid else {
        XCTFail("document.validate() failed - pos: \(result.errorPosition ?? -1), reason: \(result.reason ?? "nil")", file: file, line: line)
        return
    }
}

func assertInvalid(_ document: Document, file: StaticString = #filePath, line: UInt = #line) {
    let result = document.validate()
    guard !result.isValid else {
        XCTFail("Document validation succeeded but should not have", file: file, line: line)
        return
    }
}

var binaryData: ByteBuffer = {
    let alloc = ByteBufferAllocator()
    var buffer = alloc.buffer(capacity: 5)
    buffer.writeBytes([34,34,34,34,34])
    return buffer
}()

final class BSONPublicTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }

    static var allTests : [(String, (BSONPublicTests) -> () throws -> Void)] {
        return [
            ("testDocumentLockup", testDocumentLockup),
            ("testBasicUsage", testBasicUsage),
            ("testObjectIdUniqueness", testObjectIdUniqueness),
            ("testDecoding", testDecoding),
            ("testDictionaryLiteral", testDictionaryLiteral),
//            ("testDocumentCollectionFunctionality", testDocumentCollectionFunctionality),
//            ("testInitializedFromData", testInitializedFromData),
//            ("testArrayRelatedFunctions", testArrayRelatedFunctions),
//            ("testMultipleDocumentsInitialization", testMultipleDocumentsInitialization),
//            ("testInitFromFoundationData", testInitFromFoundationData),
//            ("testSerialization", testSerialization),
//            ("testValidation", testValidation),
//            ("testObjectId", testObjectId),
//            ("testObjectIdString", testObjectIdString),
//            ("testObjectIdHash", testObjectIdHash ),
//            ("testDocumentIndexes", testDocumentIndexes),
//            ("testComparison", testComparison),
//            ("testMultiSyntax", testMultiSyntax),
//            ("testDocumentCombineOperators", testDocumentCombineOperators),
//            ("testDocumentFlattening", testDocumentFlattening),
//            ("testTypeChecking", testTypeChecking),
//            ("testCacheCorruption", testCacheCorruption),
//            ("testBinaryEquatable", testBinaryEquatable),
//            ("testUsingDictionaryAsPrimitive", testUsingDictionaryAsPrimitive)
        ]
    }

    let kittenDocument: Document = {
        return [
            "doubleTest": 0.04,
            "stringTest": "foo",
            "documentTest": [
                "documentSubDoubleTest": 13.37,
                "subArray": ["henk", "fred", "kaas", "goudvis"] as Document
            ] as Document,
            "nonRandomObjectId": ObjectId("0123456789ABCDEF01234567"),
            "currentTime": Date(timeIntervalSince1970: Double(1453589266)),
            "cool32bitNumber": Int32(9001),
            "cool64bitNumber": 21312153,
            "code": JavaScriptCode("console.log(\"Hello there\");"),
            "codeWithScope": JavaScriptCodeWithScope("console.log(\"Hello there\");", scope: ["hey": "hello"]),
            "nothing": Null(),
            "data": Binary(subType: .generic, buffer: binaryData),
            "boolFalse": false,
            "boolTrue": true,
            "timestamp": Timestamp(increment: 2000, timestamp: 8),
            "regex": RegularExpression(pattern: "[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}", options: ""),
            "minKey": MinKey(),
            "maxKey": MaxKey()
        ] as Document
    }()

    func testBasicUsage() {
        var doc = Document()
        
        XCTAssertEqual(doc.keys.count, 0)
        
        doc["int32"] = 4 as Int32
        XCTAssertEqual(doc.keys, ["int32"])
    }
    
    func testSubdocumentBasicAccess()  throws{
        var doc = Document()
        let subdoc = ["foo": "bar"] as Document
        assertValid(subdoc)
        doc["a"] = subdoc
        assertValid(doc)
        XCTAssertEqual(doc["a"]["foo"] as? String, "bar")
    }
    
    func testShrinkingDocument() {
        var doc: Document = ["hello"]
        doc[0] = "ello"
        XCTAssertTrue(doc.validate().isValid)
    }
    
    func testExpandSubarray() {
        let s = String(repeating: "sdasfgnsdkjfls;akdflnbkjfajd;sflklnbfsadkmlv", count: 100)
        var doc = Document()
        var array: Document = []
        array.append("")
        array.append("")
        array.append("")
        array.append("")
        array.append("")
        array.append("")
        array.append("")
        doc["arr"] = array
        array[1] = s
        doc["arr"] = array
        array.append("String")
        doc["arr"] = array
        
        XCTAssert(doc.validate().isValid)
        XCTAssert(array.validate().isValid)
        XCTAssertEqual((doc["arr"] as! Document)[1] as? String, s)
    }
    
    func testEncodeSingleValue() throws {
        let date = Date()
        XCTAssertTrue(try BSONEncoder().encodePrimitive(date) is Date)
        XCTAssertFalse(try BSONEncoder().encodePrimitive(date) is Double)
    }
    
    func testRemoveArray() throws {
        var array: Document = ["ACXZCXZCXZZX", "BaSDASDASAS", "C"]
        XCTAssertEqual(array.values.count, 3)
        array.remove(at: 0)
        XCTAssertEqual(array, ["BaSDASDASAS", "C"])
    }
    
    func testDecodeSingleValue() throws {
        let date = Date()
        let sameDate = try BSONDecoder().decode(Date.self, fromPrimitive: date)
        XCTAssertEqual(date, sameDate)
    }
    
    func testIteration() {
        let doc: Document = [
            "a", "b", "c", "d"
        ]
        
        var iter = doc.makeIterator()
        
        XCTAssertEqual(iter.next()?.1 as? String, "a")
        XCTAssertEqual(iter.next()?.1 as? String, "b")
        XCTAssertEqual(iter.next()?.1 as? String, "c")
        XCTAssertEqual(iter.next()?.1 as? String, "d")
        XCTAssertNil(iter.next()?.1)
    }

    func testperf() throws {
        for _ in 0..<10_000 {
            let id = ObjectId()
            var doc = Document()
            doc["_id"] = id
            doc["hello"] = "world"
            doc["num"] = 42
            doc["subdoc"]["awesome"] = true

            let doc2 = [
                "_id": id,
                "hello": "world",
                "num": 42,
                "subdoc": [
                    "awesome": true
                ] as Document
            ] as Document

            @inline(__always)
            func equal<T: Equatable>(_ type: T.Type, key: String) {
                XCTAssertEqual(doc[key] as? T, doc2[key] as? T)
            }

            equal(ObjectId.self, key: "_id")
            equal(String.self, key: "hello")
            equal(Int.self, key: "num")
            equal(Document.self, key: "subdoc")
        }
    }
    
    func testContainsKey() {
        var doc = Document()
        doc["_id"] = ObjectId()
        
        XCTAssertTrue(doc.containsKey("_id"))
        XCTAssertFalse(doc.containsKey("_Id"))
        XCTAssertFalse(doc.containsKey("id"))
    }
    
    func testInsert() {
        var doc = Document()
        doc["name"] = "Joannis"
        
        doc.insert(ObjectId(), forKey: "_id", at: 0)
        XCTAssertEqual(doc.keys, ["_id", "name"])
        
        doc.insert(ObjectId(), forKey: "parent", at: 1)
        XCTAssertEqual(doc.keys, ["_id", "parent", "name"])
        
        doc.insert(ObjectId(), forKey: "parent2", at: 3)
        XCTAssertEqual(doc.keys, ["_id", "parent", "name", "parent2"])
    }
    
    func testBinaryOverwrite() {
        struct User: Codable {
            let id: ObjectId
            let data: Data
        }
        
        let data = Data(repeating: 0x01, count: 4_096 * 8)
        let alloc = ByteBufferAllocator()
        var buffer = alloc.buffer(capacity: data.count)
        buffer.writeBytes(data)
        var doc: Document = ["data": "hi"]
        doc["data"] = Binary(buffer: buffer)
        doc["data"] = data
        
        guard let binary = doc["data"] as? Binary else {
            XCTFail()
            return
        }
        
        XCTAssert(doc.validate().isValid)
        XCTAssert(binary.count == 4_096 * 8)
        XCTAssert(binary.data == data)
    }
    
    func testInitObjectIdFromString() throws {
        for _ in 0..<1_000 {
            let id = ObjectId()
            let string = id.hexString
            let id2 = try ObjectId.make(from: string)
            XCTAssertEqual(id, id2)
            let string2 = id2.hexString
            let id3 = try ObjectId.make(from: string2)
            XCTAssertEqual(id, id3)
            // Apprantly -2 wasn't enough because my PC can sometimes be THAT slow
            XCTAssertGreaterThanOrEqual(id3.date, Date().addingTimeInterval(-2))
            XCTAssertLessThanOrEqual(id3.date, Date().addingTimeInterval(2))
        }
    }
    
    func testDecoding() throws {
        struct HugeDocument: Codable {
            var _id: ObjectId
            var age: UInt8
            var year: Int16
            var epoch: Int32
            var bigNum: Int64
            var biggerNum: UInt64
            var awesome: Bool
            var pi: Float
            var morePi: Double
        }

        let id = ObjectId()

        let doc: Document = [
            "_id": id,
            "age": 244,
            "year": 1774,
            "epoch": 1522809334 as Int32,
            "bigNum": Int.max,
            "biggerNum": 1,
            "awesome": true,
            "pi": 3.14,
            "morePi": 3.14
        ]

        let decoder = BSONDecoder()

        let huge = try decoder.decode(HugeDocument.self, from: doc)
        XCTAssertEqual(huge._id, id)
        XCTAssertEqual(huge.age, 244)
        XCTAssertEqual(huge.year, 1774)
        XCTAssertEqual(huge.epoch, 1522809334)
        XCTAssertEqual(huge.bigNum, .max)
        XCTAssertEqual(huge.biggerNum, 1)
        XCTAssertEqual(huge.awesome, true)
        XCTAssertEqual(huge.pi, 3.14)
        XCTAssertEqual(huge.morePi, 3.14)
    }
    
    func testEquality() {
        var document: Document = [
            "dict": [
                "lhs": true,
                "rhs": false
            ]
        ]
        
        var otherDocument: Document = [
            "dict": [
                "rhs": false,
                "lhs": true
            ]
        ]
        
        XCTAssertEqual(document, otherDocument)
        
        document = [
            "dict": [
                "lhs",
                "rhs",
            ]
        ]
        
        otherDocument = [
            "dict": [
                "rhs",
                "lhs"
            ]
        ]
        
        XCTAssertNotEqual(document, otherDocument)
    }
    
    func testDocumentLockup() {
        var document = Document()
        document["_id"] = nil
        assertValid(document)
        document["_id"] = "123"
        assertValid(document)
        XCTAssertEqual(document["_id"] as? String, "123")
        XCTAssert(document.keys.contains("_id"))
        document["_id"] = nil
        assertValid(document)
        XCTAssertEqual(document["_id"] as? String, nil)
        XCTAssertFalse(document.keys.contains("_id"))
        document["_id"] = "456"
        assertValid(document)
        XCTAssertEqual(document["_id"] as? String, "456")
        XCTAssert(document.keys.contains("_id"))
        document["anykey"] = "anyvalue"
        assertValid(document)
        XCTAssertEqual(document["anykey"] as? String, "anyvalue")
        document["_id"] = "abcdefghijklmnop"
        XCTAssertEqual(document["_id"] as? String, "abcdefghijklmnop")
        document["_id"] = "efg"
        XCTAssertEqual(document["_id"] as? String, "efg")
        assertValid(document)

        var document2 = Document()
        document2["anykey"] = nil
        assertValid(document2)
        document2["_id"] = "123"
        assertValid(document2)
        XCTAssertNotNil(document2["_id"])

        var document3 = Document()
        document3["_id"] = "123"
        assertValid(document3)
        XCTAssertEqual(document3["_id"] as? String, "123")
        document2["anykey"] = nil
        assertValid(document3)
        XCTAssertEqual(document3["_id"] as? String, "123")
        XCTAssert(document.keys.contains("anykey"))
    }

//    func testNullToNilInt() {
//        var doc: Document = [
//            "_id": Null(),
//            "name": "Joannis",
//            "email": "joannis@orlandos.nl"
//        ]
//
//        XCTAssert(doc.validate().isValid)
//        XCTAssertEqual(doc["_id"] as? Null, Null())
//
//        XCTAssert(doc.validate().isValid)
//        XCTAssertEqual(doc["_id"], nil)
//    }
//
//    func testNullToNilString() {
//        var doc: Document = [
//            "_id": Null(),
//            "name": "Joannis",
//            "email": "joannis@orlandos.nl"
//        ]
//
//        XCTAssert(doc.validate().isValid)
//        XCTAssertEqual(doc.typeIdentifier(of: "_id"), .nullValue)
//
//        doc["_id"] = nil
//
//        XCTAssert(doc.validate().isValid)
//        XCTAssertEqual(doc.typeIdentifier(of: "_id"), nil)
//    }

    func validateAgainstKitten(_ document: Document) {
        XCTAssertEqual(document.count, 17) //yes, hardcoded!
        XCTAssertEqual(document.makeData(), kittenDocument.makeData())
    }

    func testDictionaryLiteral() {
        XCTAssertEqual(kittenDocument["doubleTest"] as? Double, 0.04)
        XCTAssertEqual(kittenDocument["nonRandomObjectId"] as? ObjectId, ObjectId("0123456789ABCDEF01234567"))
    }

    func testDocumentCollectionFunctionality() {
        var document = kittenDocument

        assertValid(document)
        XCTAssertEqual(document.removeValue(forKey: "stringTest") as? String, "foo")
        assertValid(document)
        XCTAssertEqual(document["stringTest"] as? String, nil)
        XCTAssertEqual(document.removeValue(forKey: "stringTest") as? String, nil)
        assertValid(document)
        
        let keys: Set<String> = [
            "doubleTest",
            "documentTest",
            "nonRandomObjectId",
            "currentTime",
            "cool32bitNumber",
            "cool64bitNumber",
            "code",
            "codeWithScope",
            "nothing",
            "data",
            "boolFalse",
            "boolTrue",
            "timestamp",
            "regex",
            "minKey",
            "maxKey",
        ]

        XCTAssertEqual(Set(document.keys), keys)
        assertValid(document)
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

//    func testInitializedFromData() {
//        let document = Document(bytes: [121, 1, 0, 0, 1, 100, 111, 117, 98, 108, 101, 84, 101, 115, 116, 0, 123, 20, 174, 71, 225, 122, 164, 63, 2, 115, 116, 114, 105, 110, 103, 84, 101, 115, 116, 0, 4, 0, 0, 0, 102, 111, 111, 0, 3, 100, 111, 99, 117, 109, 101, 110, 116, 84, 101, 115, 116, 0, 102, 0, 0, 0, 1, 100, 111, 99, 117, 109, 101, 110, 116, 83, 117, 98, 68, 111, 117, 98, 108, 101, 84, 101, 115, 116, 0, 61, 10, 215, 163, 112, 189, 42, 64, 4, 115, 117, 98, 65, 114, 114, 97, 121, 0, 56, 0, 0, 0, 2, 48, 0, 5, 0, 0, 0, 104, 101, 110, 107, 0, 2, 49, 0, 5, 0, 0, 0, 102, 114, 101, 100, 0, 2, 50, 0, 5, 0, 0, 0, 107, 97, 97, 115, 0, 2, 51, 0, 8, 0, 0, 0, 103, 111, 117, 100, 118, 105, 115, 0, 0, 0, 7, 110, 111, 110, 82, 97, 110, 100, 111, 109, 79, 98, 106, 101, 99, 116, 73, 100, 0, 1, 35, 69, 103, 137, 171, 205, 239, 1, 35, 69, 103, 9, 99, 117, 114, 114, 101, 110, 116, 84, 105, 109, 101, 0, 80, 254, 171, 112, 82, 1, 0, 0, 16, 99, 111, 111, 108, 51, 50, 98, 105, 116, 78, 117, 109, 98, 101, 114, 0, 41, 35, 0, 0, 18, 99, 111, 111, 108, 54, 52, 98, 105, 116, 78, 117, 109, 98, 101, 114, 0, 200, 167, 77, 246, 4, 0, 0, 0, 13, 99, 111, 100, 101, 0, 28, 0, 0, 0, 99, 111, 110, 115, 111, 108, 101, 46, 108, 111, 103, 40, 34, 72, 101, 108, 108, 111, 32, 116, 104, 101, 114, 101, 34, 41, 59, 0, 15, 99, 111, 100, 101, 87, 105, 116, 104, 83, 99, 111, 112, 101, 0, 56, 0, 0, 0, 28, 0, 0, 0, 99, 111, 110, 115, 111, 108, 101, 46, 108, 111, 103, 40, 34, 72, 101, 108, 108, 111, 32, 116, 104, 101, 114, 101, 34, 41, 59, 0, 20, 0, 0, 0, 2, 104, 101, 121, 0, 6, 0, 0, 0, 104, 101, 108, 108, 111, 0, 0, 10, 110, 111, 116, 104, 105, 110, 103, 0, 0])
//
//        // {"cool32bitNumber":9001,"cool64bitNumber":{"$numberLong":"21312153544"},"currentTime":{"$date":"1970-01-17T19:46:29.266Z"},"documentTest":{"documentSubDoubleTest":13.37,"subArray":{"0":"henk","1":"fred","2":"kaas","3":"goudvis"}},"doubleTest":0.04,"nonRandomObjectId":{"$oid":"0123456789abcdef01234567"},"nothing":null,"stringTest":"foo"}
//
//        XCTAssertEqual(Int32(lossy: document["cool32bitNumber"]), Int32(9001))
//        XCTAssertEqual(Int(lossy: document["cool64bitNumber"]), 21312153544)
//        XCTAssertEqual(Double(lossy: document["documentTest", "documentSubDoubleTest"]), 13.37)
//        XCTAssertEqual(String(lossy: document["documentTest", "subArray", 1]), "fred")
//        XCTAssertEqual(Double(lossy: document["doubleTest"]), 0.04)
//        XCTAssert(document["nothing"] as? Null != nil)
//        XCTAssertEqual(Document(lossy: document["nonexistentkey"]), nil)
//        XCTAssertEqual(String(lossy: document["stringTest"]), "foo")
//    }
//
//    func testArrayRelatedFunctions() {
//        let document: Document = ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z"]
//        XCTAssertTrue(document.validatesAsArray())
//        XCTAssertEqual(document.count, 26)
//
//        let date = Date()
//        let arrayDoc: Document = ["kaas", "sap", "saus", 55, "fred", ["subDocument": true] as Document, 44.3, date]
//
//        XCTAssertTrue(arrayDoc.validatesAsArray())
//
//        let bytes = arrayDoc.bytes
//        let reInstantiated = Document(bytes: bytes)
//
//        let arrayValue = reInstantiated.arrayRepresentation
//
//        XCTAssertEqual(arrayDoc.count, arrayValue.count)
//        XCTAssertEqual(arrayValue[0] as? String, "kaas")
//
//        let anArray: Document = ["0": "hoi", "1": "kaas", "2": "fred"]
//        XCTAssertFalse(anArray.validatesAsArray())
//        XCTAssertFalse(kittenDocument.validatesAsArray())
//
//        // TODO: BSON specifies that arrays should be stored in the correct sequence
//        // We never had good support for this, so far. Make a github issue!
////        let notAnArray: Document = ["0": "kaas", "3": "fred", "2": "hoi", "1": 4]
////        XCTAssertFalse(notAnArray.validatesAsArray())
//
//
//        var array: Document = [Int32(0), Int32(1), Int32(2), Int32(3), Int32(4)]
//        array[1] = "hello"
//
//        XCTAssertEqual(Int32(lossy: array[0]), Int32(0))
//        XCTAssertNotEqual(Int32(lossy: array[1]), Int32(1))
//        XCTAssertEqual(String(lossy: array[1]), "hello")
//        XCTAssertEqual(Int32(lossy: array[2]), Int32(2))
//        XCTAssertEqual(Int32(lossy: array[3]), Int32(3))
//        XCTAssertEqual(Int32(lossy: array[4]), Int32(4))
//    }
//
//    func testMultipleDocumentsInitialization() {
//        let doc1: Document = ["kaas", "sap", "saus"]
//        let doc2 = kittenDocument
//        let doc3: Document = ["hoi": "test", "3": 24]
//
//        let data = doc1.bytes + doc2.bytes + doc3.bytes
//
//        let singleDoc = Document(bytes: data)
//        XCTAssertEqual(singleDoc.bytes, doc1.bytes)
//
//        let multipleDocs = [Document](bsonBytes: data)
//        XCTAssertEqual(multipleDocs.count, 3)
//        XCTAssertEqual(multipleDocs[0].bytes, doc1.bytes)
//        XCTAssertEqual(multipleDocs[1].bytes, doc2.bytes)
//        XCTAssertEqual(multipleDocs[2].bytes, doc3.bytes)
//
//        validateAgainstKitten(multipleDocs[1])
//    }
//
//    func testInitFromFoundationData() {
//        let document = Document(bytes: kittenDocument.bytes)
//        XCTAssertEqual(document.bytes, kittenDocument.bytes)
//    }
//
//    func testSerialization() {
//        let originalBinary: Data = Data([5,0,0,0,0,5,0,0,0,0])
//
//        let documents = [Document](bsonBytes: originalBinary)
//
//        XCTAssertEqual(documents.count, 2)
//        XCTAssertEqual(documents.bytes, originalBinary)
//
//        XCTAssertEqual(documents[0].byteCount, 5)
//        XCTAssertEqual(documents[0].bytes, Data([5,0,0,0,0]))
//    }
//
//    func testValidation() {
//        XCTAssertTrue(kittenDocument.validate())
//        XCTAssertFalse(Document(bytes: [0,0,0,0,0]).validate()) ??? todo?
//        XCTAssertFalse(Document(bytes: [4,0,4,0,6,4,32,43,3,2,2,5,6,63]).validate())
//
//        let documents0 = [Document](bytes: [5,0,0,0,0,0,0,0,0,0])
//        let documents1 = [Document](bytes: [5,0,0,0,0,6,0,0,0,0])
//
//        XCTAssertEqual(documents0.count, 1)
//        XCTAssertEqual(documents1.count, 1)
//
//        let documentsBytes = kittenDocument.bytes + [9,0,0,0,1,40,0,20,0]
//
//        let containsInvalidDocument = [Document](bsonBytes: documentsBytes)
//        let containsValidDocuments = [Document](bsonBytes: documentsBytes, validating: true)
//
//        XCTAssertEqual(containsInvalidDocument.count, 2)
//        XCTAssertEqual(containsValidDocuments.count, 1)
//
//        let invalidTypeDocument = Document(bytes: [16,0,0,0,80,40,40,40,40,40,0,6,0,0,0,0,40,40,40,40,40,0,0])
//
//        for _ in invalidTypeDocument {
//            XCTFail()
//        }
//    }
//
//    func testObjectId() throws {
//        let random = ObjectId()
//
//        let hs = "AFAAABACADAEA0A1A2A3A4A2"
//        let fromHex = try ObjectId(hs)
//
//        XCTAssertEqual(fromHex._storage[0], 0xAF)
//        XCTAssertEqual(fromHex._storage[1], 0xAA)
//        XCTAssertEqual(fromHex._storage[2], 0xAB)
//        XCTAssertEqual(fromHex._storage[3], 0xAC)
//        XCTAssertEqual(fromHex._storage[4], 0xAD)
//        XCTAssertEqual(fromHex._storage[5], 0xAE)
//        XCTAssertEqual(fromHex._storage[6], 0xA0)
//        XCTAssertEqual(fromHex._storage[7], 0xA1)
//        XCTAssertEqual(fromHex._storage[8], 0xA2)
//        XCTAssertEqual(fromHex._storage[9], 0xA3)
//        XCTAssertEqual(fromHex._storage[10], 0xA4)
//        XCTAssertEqual(fromHex._storage[11], 0xA2)
//
//        XCTAssertNotEqual(random.hexString, fromHex.hexString)
//        XCTAssertEqual(fromHex.hexString, hs.lowercased())
//
//        var toMutate = ObjectId()
//        toMutate._storage = random._storage
//        XCTAssertEqual(toMutate.hexString, random.hexString)
//
//        // random should not be the same
//        XCTAssertNotEqual(ObjectId()._storage, ObjectId()._storage)
//
//        // Wrong initialization string length:
//        XCTAssertThrowsError(try ObjectId("1234567890"))
//
//        // Wrong initialization data length:
//        XCTAssertThrowsError(try ObjectId(data: Data([0,1,2,3])))
//
//        // Wrong initialization string:
//        XCTAssertThrowsError(try ObjectId("kaaskaaskaaskaaskaaskaas"))
//
//        let timeId = ObjectId()
//
//        XCTAssertLessThan(timeId.epoch.timeIntervalSinceNow, 2)
//    }
//
//    func testObjectIdString() throws {
//        let stringId = try ObjectId("589488560239f4563ddc6ca0")
//        XCTAssertEqual(stringId.epochSeconds, 1486129238)
//        XCTAssertEqual(stringId.hexString, "589488560239f4563ddc6ca0")
//        XCTAssertEqual(stringId.epoch.timeIntervalSince1970, 1486129238)
//    }
//
//    func testObjectIdHash() throws {
//        let firstId = try ObjectId("589488560239f4563ddc6ca0")
//        let secondId = try ObjectId("589488560239f4563ddc6ca0")
//        let thirdId = try ObjectId("589488560239f4563ddc6cab")
//        XCTAssertEqual(firstId.hashValue, secondId.hashValue)
//        XCTAssertNotEqual(firstId.hashValue, thirdId.hashValue)
//    }
//
//    func testDocumentIndexes() {
//        let firstKittenKV = kittenDocument[kittenDocument.startIndex]
//
//        XCTAssertEqual(firstKittenKV.key, "doubleTest")
//        XCTAssertEqual(firstKittenKV.value as? Double, 0.04)
//
//        let document = kittenDocument
//
//        XCTAssert(document.startIndex < document.endIndex)
//        XCTAssertFalse(document.endIndex < document.startIndex)
//        XCTAssertEqual(document.startIndex, document.startIndex)
//
//        let secondIndex = kittenDocument.index(after: kittenDocument.startIndex)
//        XCTAssertEqual(kittenDocument[secondIndex].key, "stringTest")
//    }
//
//    func testComparison() throws {
//        XCTAssertEqual(Double(lossy: kittenDocument["doubleTest"]), 0.04)
//        XCTAssertEqual(String(lossy: kittenDocument["stringTest"]), "foo")
//
//        let documentTest = [
//            "documentSubDoubleTest": 13.37,
//            "subArray": ["henk", "fred", "kaas", "goudvis"]
//            ] as Document
//
//        XCTAssertEqual(Document(lossy: kittenDocument["documentTest"]), documentTest)
//
//        let nonRandomObjectId = try ObjectId("0123456789ABCDEF01234567")
//        XCTAssertEqual(ObjectId(lossy: kittenDocument["nonRandomObjectId"]), nonRandomObjectId)
//        XCTAssertEqual(try ObjectId("0123456789ABCDEF01234567"), nonRandomObjectId)
//        XCTAssertEqual(nonRandomObjectId.hexString.uppercased(), "0123456789ABCDEF01234567")
//
//        XCTAssertEqual(Date(lossy: kittenDocument["currentTime"]), Date(timeIntervalSince1970: Double(1453589266)))
//        XCTAssertEqual(Int32(lossy: kittenDocument["cool32bitNumber"]), 9001)
//        XCTAssertEqual(Int(lossy: kittenDocument["cool64bitNumber"]), 21312153)
//// FIXME:         XCTAssertEqual(JavascriptCode(kittenDocument["code"])?.code, "console.log(\"Hello there\");")
//        XCTAssert(kittenDocument["nothing"] is Null)
//        XCTAssertEqual(Bool(lossy: kittenDocument["boolFalse"]), false)
//        XCTAssertEqual(Bool(lossy: kittenDocument["boolTrue"]), true)
//
//        let bytes = Data([34,34,34,34,34])
//        XCTAssertEqual(Binary(lossy: kittenDocument["data"])?.data ?? Data(), bytes)
//
//        XCTAssertEqual(Timestamp(lossy: kittenDocument["timestamp"]), Timestamp(increment: 2000, timestamp: 8))
//        XCTAssertEqual(RegularExpression(lossy: kittenDocument["regex"])?.pattern, "[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}")
//        XCTAssert(kittenDocument["minKey"] is MinKey)
//        XCTAssert(kittenDocument["maxKey"] is MaxKey)
//
//        let emptyDocument = Document()
//
//        XCTAssertNotEqual(emptyDocument, [])
//        XCTAssertEqual(emptyDocument, [:])
//        XCTAssertNotEqual([:] as Document, [] as Document)
//        XCTAssertEqual([:] as Document, [:] as Document)
//        XCTAssertEqual([] as Document, [] as Document)
//
//    }
//
//    func testMultiSyntax() {
//        var d = kittenDocument
//        let v = "harriebob"
//
//        d["kaassapsaus", "freddelien"] = v
//        d["hont", "kad", "varkun", "konein"] = v
//
//        #if swift(>=3.1)
//            XCTAssertEqual(String(lossy: d["kaassapsaus"]["freddelien"]), v)
//        #endif
//
//        XCTAssertEqual(String(lossy: d["kaassapsaus", "freddelien"]), v)
//        XCTAssertEqual(Double(lossy: d["documentTest", "documentSubDoubleTest"]), 13.37)
//
//        XCTAssertEqual(String(lossy: d["hont", "kad", "varkun", "konein"]), v)
//
//        #if swift(>=3.1)
//            XCTAssertEqual(String(lossy: d["hont"]["kad"]["varkun"]["konein"]), v)
//        #endif
//    }
//
//    func testDocumentCombineOperators() {
//        let stillJustKittenDocument = kittenDocument + kittenDocument
//        validateAgainstKitten(stillJustKittenDocument)
//
//        let doc1 = ["harrie": "bob", "is": 4, "konijn": true] as Document
//        let doc2 = ["vis": "kaas", "konijn": "nee", "henk": false] as Document
//        let doc3 = doc1 + doc2
//        XCTAssertEqual(doc3, ["harrie": "bob", "is": 4, "vis": "kaas", "konijn": "nee", "henk": false])
//
//    }
//
//    // TODO: Fix this test, AssertEqual fails whilst the strins *are* equal
//    func testDocumentFlattening() throws {
//        let correctFlatKitten: Document = [
//            "doubleTest": 0.04,
//            "stringTest": "foo",
//            "documentTest.documentSubDoubleTest": 13.37,
//            "documentTest.subArray.0": "henk",
//            "documentTest.subArray.1": "fred",
//            "documentTest.subArray.2": "kaas",
//            "documentTest.subArray.3": "goudvis",
//            "nonRandomObjectId": try! ObjectId("0123456789ABCDEF01234567"),
//            "currentTime": Date(timeIntervalSince1970: Double(1453589266)),
//            "cool32bitNumber": Int32(9001),
//            "cool64bitNumber": 21312153,
//            "code": JavascriptCode(code: "console.log(\"Hello there\");"),
//            "codeWithScope": JavascriptCode(code: "console.log(\"Hello there\");", withScope: ["hey": "hello"]),
//            "nothing": Null(),
//            "data": Binary(data: [34,34,34,34,34], withSubtype: .generic),
//            "boolFalse": false,
//            "boolTrue": true,
//            "timestamp": Timestamp(increment: 2000, timestamp: 8),
//            "regex": RegularExpression(pattern: "[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}", options: []),
//            "minKey": MinKey(),
//            "maxKey": MaxKey()
//        ]
//
//        var flattenedKitten = kittenDocument
//        flattenedKitten.flatten()
//
//        XCTAssertEqual(correctFlatKitten, flattenedKitten)
//        XCTAssertTrue(flattenedKitten.validate())
//    }
//
//    func testKeyDetection() {
//        var myDoc: Document = ["balance_status": "Pending"]
//        XCTAssertEqual(String(lossy: myDoc["balance_status"]), "Pending")
//        myDoc["balance"] = 50
//        XCTAssertEqual(String(lossy: myDoc["balance_status"]), "Pending")
//        XCTAssertEqual(Int32(lossy: myDoc["balance"]), 50)
//        myDoc["balance_status"] = "Done"
//        XCTAssertEqual(String(lossy: myDoc["balance_status"]), "Done")
//        XCTAssertEqual(String(lossy: myDoc["balance"]), "50")
//
//        let name = "coll"
//        var command: Document = ["delete": name]
//        let newDeletes = ["bob", 3, true] as [Primitive]
//
//        command["deletes"] = Document(array: newDeletes)
//
//        XCTAssertEqual(String(lossy: command["delete"]), name)
//        XCTAssertEqual(Document(lossy: command["deletes"]), ["bob", 3, true])
//    }
//
//    func testTypeChecking() {
//        XCTAssertEqual(kittenDocument.type(at: 0), .double)
//        XCTAssertEqual(kittenDocument.type(at: 1), .string)
//        XCTAssertEqual(kittenDocument.type(at: 2), .document)
//        XCTAssertEqual(kittenDocument.type(at: -1), nil)
//        XCTAssertEqual(kittenDocument.type(at: 25), nil)
//        XCTAssertEqual(kittenDocument.type(at: kittenDocument.count + 1), nil)
//
//        XCTAssertEqual(kittenDocument.type(at: "doubleTest"), .double)
//        XCTAssertEqual(kittenDocument.type(at: "stringTest"), .string)
//        XCTAssertEqual(kittenDocument.type(at: "documentTest"), .document)
//        XCTAssertEqual((kittenDocument["documentTest"] as? Document)?.type(at: "subArray"), .arrayDocument)
//        XCTAssertEqual(kittenDocument.type(at: "nonRandomObjectId"), .objectId)
//        XCTAssertEqual(kittenDocument.type(at: "bob"), nil)
//        XCTAssertEqual(kittenDocument.type(at: "piet"), nil)
//        XCTAssertEqual(kittenDocument.type(at: "kenk"), nil)
//    }
//
//    func testCacheCorruption() {
//        var document: Document = try! [
//            "_id": ObjectId("5925985d7d6496b6f5346fc2"),
//            "foo": Data(bytes: [UInt8](repeatElement(0, count: 100)))
//        ]
//
//        document["foo"] = nil
//        _ = document["_id"] // did crash once
//    }
//
//    func testBinaryEquatable() {
//        XCTAssert(Binary(data: Data(), withSubtype: .generic) == Binary(data: Data(), withSubtype: .generic))
//        XCTAssertFalse(Binary(data: Data(), withSubtype: .generic) == Binary(data: Data(), withSubtype: .uuid))
//        XCTAssertFalse(Binary(data: [0x00, 0x00], withSubtype: .generic) == Binary(data: Data(), withSubtype: .generic))
//    }
//
//    func testUsingDictionaryAsPrimitive() {
//        let id = ObjectId()
//        let dictionary1: [String: Int] = [
//            "int": 5
//        ]
//        let dictionary2: [String: Primitive] = [
//            "objectid": id,
//            "int": 4
//        ]
//        let dictionary3: [String: Int?] = [
//            "int": 5,
//            "nil": nil
//        ]
//        let dictionary4: [String: Primitive?] = [
//            "objectid": id,
//            "int": 4,
//            "nil": nil
//        ]
//        let document: Document = [
//            "dictionary1": dictionary1,
//            "dictionary2": dictionary2,
//            "dictionary3": dictionary3,
//            "dictionary4": dictionary4
//        ]
//
//        XCTAssertEqual(document["dictionary1", "int"] as? Int, 5)
//        XCTAssertEqual(document["dictionary2", "objectid"] as? ObjectId, id)
//        XCTAssertEqual(document["dictionary2", "int"] as? Int, 4)
//        XCTAssertEqual(document["dictionary3", "int"] as? Int, 5)
//        XCTAssertEqual(document["dictionary4", "objectid"] as? ObjectId, id)
//        XCTAssertEqual(document["dictionary4", "int"] as? Int, 4)
//    }
}
