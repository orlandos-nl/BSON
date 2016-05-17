//
//  Compatibility.swift
//  BSON
//
//  Created by Robbert Brandsma on 17-05-16.
//
//

import XCTest

#if !swift(>=3.0)

    extension XCTestCase {
        func measure(block: () -> Void) {
            self.measureBlock(block)
        }
    }
    
#endif