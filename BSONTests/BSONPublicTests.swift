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
    
}
