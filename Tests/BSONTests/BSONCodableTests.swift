//
//  BSONCodableTests.swift
//  BSONTests
//
//  Created by Robbert Brandsma on 13/06/2017.
//

import XCTest
import BSON

class BSONCodableTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testSecuenceCoding() throws {
        let array = ["Hoi", "Sup", "abcdefghijklmnop"]
        let document = Document(array: array)
        let codedDocument = try BSONEncoder().encode(array)
        XCTAssertEqual(document.bytes, codedDocument.bytes)
    }
    
    @available(OSX 10.12, *)
    func testEncoding() throws {
        struct Cat : Encodable {
            var _id = ObjectId()
            var name = "Fred"
            var sample: Float = 5.0
            
            struct Tail : Encodable {
                var length = Measurement(value: 30, unit: UnitLength.centimeters)
            }
            var tail = Tail()
            
            var otherNames = ["King", "Queen"]
        }
        let cat = Cat()
        let doc = try BSONEncoder().encode(cat)
        XCTAssertEqual(doc["name"] as? String, cat.name)
        XCTAssertEqual(doc["_id"] as? ObjectId, cat._id)
        XCTAssertEqual(doc["sample"] as? Double, Double(cat.sample))
    }
    
    @available(OSX 10.12, *)
    func testDecoding() throws {
        struct Cat : Decodable {
            var _id: ObjectId
            var name: String
            var sample: Float
            var otherNames: [String]
        }
        
        let doc: Document = ["_id": ObjectId(), "name": "Harrie", "sample": 4.5, "otherNames": ["King", "Queen"]]
        let cat = try BSONDecoder().decode(Cat.self, from: doc)
        XCTAssertEqual(doc["name"] as? String, cat.name)
        XCTAssertEqual(doc["_id"] as? ObjectId, cat._id)
        XCTAssertEqual(doc["sample"] as? Double, Double(cat.sample))
        XCTAssertEqual(["King", "Queen"], cat.otherNames)
    }
    
}
