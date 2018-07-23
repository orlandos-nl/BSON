import Foundation
@testable import BSON
import XCTest

struct ValueCodableContainer<T: Codable>: Codable {
    var value: T
}

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
    
    func testDocumentValues() {
        let document: Document = ["a", "b"]
        XCTAssert(document.values == ["a", "b"] as [Primitive])
    }
    
    func testTimestampSerialization() {
        let stamp = Timestamp(increment: 2117261592, timestamp: -2127433148)
        let document: Document = ["a": stamp]
        let stamp2 = document["a"] as! Timestamp
        XCTAssertEqual(stamp, stamp2)
    }
    
    // types
    
    let regex = RegularExpression(pattern: " ^[ \\t]", options: "i")
    
    func testBSONRegularExpressionWritingAndReading() throws {
        let document: Document = ["regex": regex]
        XCTAssertEqual(document.regex, regex)
    }
    
    func testBSONRegularExpressionEncoding() throws {
        let container = ValueCodableContainer(value: regex)
        let document = try BSONEncoder().encode(container)
        
        XCTAssertEqual(document.value, regex)
    }
    
    func testBSONRegularExpressionDecoding() throws {
        let document: Document = ["value": regex]
        let decoded = try BSONDecoder().decode(ValueCodableContainer<RegularExpression>.self, from: document)
        
        XCTAssertEqual(decoded.value, regex)
    }
}
