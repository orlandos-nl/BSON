//
//  BSONPerformanceTests.swift
//  BSON
//
//  Created by Joannis Orlandos on 16/07/16.
//
//

import Foundation
import XCTest
@testable import BSON

#if os(Linux)
    import Glibc
#endif

class BSONPerformanceTests: XCTestCase {
    
    static var allTests : [(String, (BSONPerformanceTests) -> () throws -> Void)] {
        return [
            ("testDocumentInstantiationPerformance", testExtendedJSONPerformance)
        ]
    }
    
    func testExtendedJSONPerformance() throws {
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
            "timestamp": .timestamp(stamp: 2000, increment: 8),
            "regex": .regularExpression(pattern: "[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}", options: "b"),
            "minKey": .minKey,
            "maxKey": .maxKey
        ]
        
        measure {
            let json = kittenDocument.makeExtendedJSON()
            let document = try? Document(extendedJSON: json)
            
            XCTAssertEqual(kittenDocument, document)
        }
    }
    
    func testSerializationPerformance() {
        var total = 0
        
        measure {
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
                "timestamp": .timestamp(stamp: 2000, increment: 8),
                "regex": .regularExpression(pattern: "[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}", options: "b"),
                "minKey": .minKey,
                "maxKey": .maxKey
            ]
            
            total += kittenDocument.bytes.count
        }
        
        print("total = \(total)")
    }
    
    func testDeserializationPerformance() {
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
            "timestamp": .timestamp(stamp: 2000, increment: 8),
            "regex": .regularExpression(pattern: "[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}", options: "b"),
            "minKey": .minKey,
            "maxKey": .maxKey
        ]

        var total = 0
        
        measure {
            var hash = 0
            
            for (k, v) in kittenDocument {
                hash += k.characters.count
                hash += v.bytes.count
            }
            
            total += hash
        }
        
        print("total = \(total)")
    }
    
    func testLargeDocumentPerformance() {
        var document: Document = [:]
        
        for i in 0..<9999 {
            document.append(.int32(Int32(i)), forKey: "test\(i)")
        }
        
        measure {
            _ = document[8765]
        }
    }
    
    func testLargeDocumentPerformance2() {
        var document: Document = [:]
        
        for i in 0..<9999 {
            document.append(.int32(Int32(i)), forKey: "test\(i)")
        }
        
        measure {
            _ = document["test8765"]
        }
    }
}
