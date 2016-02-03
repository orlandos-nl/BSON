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
    
}
