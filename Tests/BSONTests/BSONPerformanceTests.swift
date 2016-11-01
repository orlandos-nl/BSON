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
                "subArray": ["henk", "fred", "kaas", "goudvis"] as Document
            ] as Document,
            "nonRandomObjectId": try! ObjectId("0123456789ABCDEF01234567"),
            "currentTime": Date(timeIntervalSince1970: Double(1453589266)),
            "cool32bitNumber": Int32(9001),
            "cool64bitNumber": Int64(21312153544),
            "code": Value.javascriptCode("console.log(\"Hello there\");"),
            "codeWithScope": Value.javascriptCodeWithScope(code: "console.log(\"Hello there\");", scope: ["hey": "hello"]),
            "nothing": Null(),
            "data": Binary(data: [34,34,34,34,34], withSubtype: .generic),
            "boolFalse": false,
            "boolTrue": true,
            "timestamp": Value.timestamp(try fromBytes(UInt32(2000).makeBytes() + UInt32(8).makeBytes()) as Int64),
            "regex": Value.regularExpression(pattern: "[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}", options: "b"),
            "minKey": Value.minKey,
            "maxKey": Value.maxKey
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
                    "subArray": ["henk", "fred", "kaas", "goudvis"] as Document
                ] as Document,
                "nonRandomObjectId": try! ObjectId("0123456789ABCDEF01234567"),
                "currentTime": Date(timeIntervalSince1970: Double(1453589266)),
                "cool32bitNumber": Int32(9001),
                "cool64bitNumber": Int64(21312153544),
                "code": JavascriptCode("console.log(\"Hello there\");"),
                "codeWithScope": JavascriptCode("console.log(\"Hello there\");", withScope: ["hey": "hello"]),
                "nothing": Null(),
                "data": Binary(data: [34,34,34,34,34], withSubtype: .generic),
                "boolFalse": false,
                "boolTrue": true,
                "timestamp": Value.timestamp(try! fromBytes(UInt32(2000).makeBytes() + UInt32(8).makeBytes()) as Int64),
                "regex": Value.regularExpression(pattern: "[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}", options: "b"),
                "minKey": Value.minKey,
                "maxKey": Value.maxKey
            ]
            
            total += kittenDocument.bytes.count
        }
        
        print("total = \(total)")
    }
    
    func testDeserializationPerformance() throws {
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
            "cool64bitNumber": Int64(21312153544),
            "code": JavascriptCode("console.log(\"Hello there\");"),
            "codeWithScope": JavascriptCode("console.log(\"Hello there\");", withScope: ["hey": "hello"]),
            "nothing": Null(),
            "data": Binary(data: [34,34,34,34,34], withSubtype: .generic),
            "boolFalse": false,
            "boolTrue": true,
            "timestamp": Value.timestamp(try fromBytes(UInt32(2000).makeBytes() + UInt32(8).makeBytes()) as Int64),
            "regex": Value.regularExpression(pattern: "[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}", options: "b"),
            "minKey": Value.minKey,
            "maxKey": Value.maxKey
        ]

        var total = 0
        
        measure {
            var hash = 0
            
            for (k, v) in kittenDocument {
                hash += k.characters.count
                hash += v.makeBsonValue().bytes.count
            }
            
            total += hash
        }
        
        print("total = \(total)")
    }
    
    func testLargeDocumentPerformance() {
        var document: Document = [:]
        
        for i in 0..<9999 {
            document.append(Int32(i), forKey: "test\(i)")
        }
        
        measure {
            _ = document[8765]
        }
    }
    
    func testLargeDocumentPerformance2() {
        var document: Document = [:]
        
        for i in 0..<9999 {
            document.append(Int32(i), forKey: "test\(i)")
        }
        
        measure {
            _ = document["test8765"]
        }
    }
    
    func testObjectidPerformance() {
        measure {
            for _ in 0..<10_000 {
                _ = ObjectId()
            }
        }
    }
}
