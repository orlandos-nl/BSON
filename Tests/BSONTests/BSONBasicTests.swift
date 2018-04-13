import Foundation
@testable import BSON
import XCTest

class BSONBasicTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testDocumentArrayMutation() {
        var document: Document = [
            "foo": ["a", "b"]
        ]
        
        XCTAssert((document["foo"] as! Document).isArray)
        document["foo"]["bar"] = "c"
        XCTAssertFalse((document["foo"] as! Document).isArray)
    }
}
