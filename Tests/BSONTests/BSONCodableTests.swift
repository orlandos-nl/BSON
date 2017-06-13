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
    
    func testExample() throws {
        struct Cat : Encodable {
            var _id = ObjectId()
            var name = "Fred"
        }
        
        let cat = Cat()
        let doc = try BSONEncoder().encode(cat)
        XCTAssertEqual(doc["name"] as? String, cat.name)
    }
    
}
