import Foundation
import BSON
import XCTest

@available(iOS 10.0, *)
class BSONEncoderTests: XCTestCase {
    func testData() throws {
        struct User: Codable {
            let _id: ObjectId
            let username: String
            let data: Data
        }
        
        let user = User(_id: ObjectId(), username: "Joannis", data: "test".data(using: .utf8)!)
        let doc = try BSONEncoder().encode(user)
        print(doc.keys)
        let copy = try BSONDecoder().decode(User.self, from: doc)
        XCTAssertEqual(user._id, copy._id)
        XCTAssertEqual(user.username, copy.username)
        XCTAssertEqual(user.data, copy.data)
    }
    
    func testEncodeBSONNull() throws {
        let string = try String(data: JSONEncoder().encode(Null()), encoding: .utf8)
        XCTAssertEqual(string, "null")
    }

    func testEncodeDocument() throws {
//        for _ in 0..<1000 {
            struct User: Codable {
                let name: String
                let age: Int
                let pets: [String]
            }

            let user = User(name: "Bob", age: 42, pets: ["Snuffles", "Doodles", "Noodles"])

            let doc = try BSONEncoder().encode(user)

            let user2 = try BSONDecoder().decode(User.self, from: doc)

            XCTAssertEqual(user.name, user2.name)
            XCTAssertEqual(user.age, user2.age)
            XCTAssertEqual(user.pets, user2.pets)
//        }
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

    private func validateEncodesAsPrimitive<T : Primitive>(_ value: T) throws -> Bool {
        let wrapped = Wrapper(value: value)
        let encodedDocument = try BSONEncoder().encode(wrapped)
        return encodedDocument["value"] is T
    }

    private func validateEncodedResult<T : Equatable & Codable, R : Primitive & Equatable>(_ value: T, expected: R) throws -> Bool {
        let wrapped = Wrapper(value: value)
        let encodedDocument = try BSONEncoder().encode(wrapped)
        return encodedDocument["value"] as? R == expected
    }

//    func testObjectIdEncodesAsPrimitive() throws {
//        try XCTAssert(validateEncodesAsPrimitive(ObjectId()))
//    }

    func testDateEncodesAsPrimitive() throws {
        try XCTAssert(validateEncodesAsPrimitive(Date()))
    }

//    func testDataEncodesAsBinary() throws {
//        try XCTAssert(validateEncodedResult(Data(), expected: Binary(data: [], withSubtype: .generic)))
//    }

    func testFloatEncodesAsDouble() throws {
        let floatArray: [Float] = [4]
        let codedDocument = try BSONEncoder().encode(floatArray)
        XCTAssertEqual(codedDocument["0"] as? Double, 4)
    }

    @available(OSX 10.12, *)
    func testEncoding() throws {
        @available(iOS 10.0, *)
        struct Cat : Encodable {
            var _id = ObjectId()
            var name = "Fred"
            var sample: Float = 5.0

            #if !os(Linux)
            @available(iOS 10.0, *)
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
    
}
