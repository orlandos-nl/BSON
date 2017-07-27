//
//  BSONCodableTests.swift
//  BSONTests
//
//  Created by Robbert Brandsma on 13/06/2017.
//

#if swift(>=3.2)
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
    
    func testArrayCodingDecodesCorrectly() throws {
        let array = ["Hoi", "Sup", "abcdefghijklmnop"]
        let document = Document(array: array)
        let codedDocument = try BSONEncoder().encode(array)
        XCTAssertEqual(document.bytes, codedDocument.bytes)
        let decodedArray = try BSONDecoder().decode([String].self, from: codedDocument)
        XCTAssertEqual(decodedArray, array)
    }
    
    func testSetEncodingDecodesCorrectly() throws {
        let set: Set<String> = ["Hoi", "Sup", "abcdefghijklmnop"]
        let codedDocument = try BSONEncoder().encode(set)
        let decodedSet = try BSONDecoder().decode(Set<String>.self, from: codedDocument)
        XCTAssertEqual(decodedSet, set)
    }
    
    func testDictionaryEncodingDecodesCorrectly() throws {
        let dictionary = ["sample": 4.0, "other": 2.0]
        let codedDocument = try BSONEncoder().encode(dictionary)
        let decodedDictionary = try BSONDecoder().decode([String: Double].self, from: codedDocument)
        XCTAssertEqual(decodedDictionary, dictionary)
    }
    
    private struct Wrapper<T : Codable> : Codable {
        var value: T
    }
    
    private func validateEncodesAsPrimitive<T : Primitive & Codable>(_ value: T) throws -> Bool {
        let wrapped = Wrapper(value: value)
        let encodedDocument = try BSONEncoder().encode(wrapped)
        return encodedDocument["value"] is T
    }
    
    private func validateEncodedResult<T : Equatable & Codable, R : Primitive & Equatable>(_ value: T, expected: R) throws -> Bool {
        let wrapped = Wrapper(value: value)
        let encodedDocument = try BSONEncoder().encode(wrapped)
        return encodedDocument["value"] as? R == expected
    }
    
    func testObjectIdEncodesAsPrimitive() throws {
        try XCTAssert(validateEncodesAsPrimitive(ObjectId()))
    }
    
    func testDateEncodesAsPrimitive() throws {
        try XCTAssert(validateEncodesAsPrimitive(Date()))
    }
    
    func testDataEncodesAsBinary() throws {
        try XCTAssert(validateEncodedResult(Data(), expected: Binary(data: [], withSubtype: .generic)))
    }
    
    func testFloatEncodesAsDouble() throws {
        let floatArray: [Float] = [4]
        let codedDocument = try BSONEncoder().encode(floatArray)
        XCTAssertEqual(codedDocument[0] as? Double, 4)
    }
    
    @available(OSX 10.12, *)
    func testEncoding() throws {
        struct Cat : Encodable {
            var _id = ObjectId()
            var name = "Fred"
            var sample: Float = 5.0
            
            #if !os(Linux)
            struct Tail : Encodable {
                var length = Measurement(value: 30, unit: UnitLength.centimeters)
            }
            var tail = Tail()
            #endif
            
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
#endif
