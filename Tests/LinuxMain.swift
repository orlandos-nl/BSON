#if os(Linux)

import XCTest
@testable import BSONTestSuite

XCTMain([testCase(BSONInternalTests.allTests),
         testCase(BSONPublicTests.allTests)])

#endif