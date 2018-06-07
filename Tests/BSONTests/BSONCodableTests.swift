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
    
    @available(OSX 10.12, *)
    func testUserInfo() {
        
        let nonCodable = NonCodable()
        
        var container = NonCodableContainer (label: "A", nonCodable: nonCodable)
        XCTAssertEqual ("A", container.label)
        XCTAssertTrue (container.nonCodable === nonCodable)
        // Error (userInfo does not container the expected value)
        let encoder = BSONEncoder()
        var decoder = BSONDecoder()
        var document = Document()
        do {
            document = try encoder.encode(container)
        } catch {
            XCTFail ("Expected success but got \(error)")
        }
        do {
            try container = decoder.decode(NonCodableContainer.self, from: document)
            XCTFail ("Expected Error")
        } catch NonCodableError.noNonCodable {} catch {
            XCTFail ("Expected NonCodableError.noNonCodable but got \(error)")
        }
        decoder = BSONDecoder(userInfo: nil)
        do {
            try container = decoder.decode(NonCodableContainer.self, from: document)
            XCTFail ("Expected Error")
        } catch NonCodableError.noNonCodable {} catch {
            XCTFail ("Expected NonCodableError.noNonCodable but got \(error)")
        }
        decoder = BSONDecoder(userInfo: [:])
        do {
            try container = decoder.decode(NonCodableContainer.self, from: document)
            XCTFail ("Expected Error")
        } catch NonCodableError.noNonCodable {} catch {
            XCTFail ("Expected NonCodableError.noNonCodable but got \(error)")
        }
        // userInfo contains nonCodable
        let userInfo: [CodingUserInfoKey : Any] = [NonCodableContainer.nonCodableKey : nonCodable]
        decoder = BSONDecoder (userInfo: userInfo)
        do {
            try container = decoder.decode(NonCodableContainer.self, from: document)
            XCTAssertEqual ("A", container.label)
            XCTAssertTrue (nonCodable === container.nonCodable)
        } catch {
            XCTFail ("Expected success")
        }
        // Test Decoding of Array<AnswerContainer> which depends on userInfo
        // No nonCodable in userInfo
        let nonCodableArray = [NonCodableContainer (label:"A", nonCodable: nonCodable), NonCodableContainer (label:"B", nonCodable: nonCodable)]
        do {
            document = try encoder.encode(nonCodableArray)
        } catch {
            XCTFail ("Expected success")
        }
        decoder = BSONDecoder()
        do {
            let _ = try decoder.decode(Array<NonCodableContainer>.self, from: document)
            XCTFail ("Expected error")
        } catch NonCodableError.noNonCodable {} catch {
            XCTFail ("Expected NonCodableError.noNonCodable but got \(error)")
        }
        decoder = BSONDecoder(userInfo: nil)
        do {
            let _ = try decoder.decode(Array<NonCodableContainer>.self, from: document)
            XCTFail ("Expected error")
        } catch NonCodableError.noNonCodable {} catch {
            XCTFail ("Expected NonCodableError.noNonCodable but got \(error)")
        }
        decoder = BSONDecoder(userInfo: [:])
        do {
            let _ = try decoder.decode(Array<NonCodableContainer>.self, from: document)
            XCTFail ("Expected error")
        } catch NonCodableError.noNonCodable {} catch {
            XCTFail ("Expected NonCodableError.noNonCodable but got \(error)")
        }
        // userInfo contains nonCodable
        decoder = BSONDecoder(userInfo: userInfo)
        do {
            let decodedArray = try decoder.decode(Array<NonCodableContainer>.self, from: document)
            XCTAssertEqual (2, decodedArray.count)
            XCTAssertEqual ("A", decodedArray[0].label)
            XCTAssertTrue (decodedArray[0].nonCodable === nonCodable)
            XCTAssertEqual ("B", decodedArray[1].label)
            XCTAssertTrue (decodedArray[1].nonCodable === nonCodable)

        } catch {
            XCTFail ("Expected success but got \(error)")
        }
        // Test Decoding of Dictionary<String, AnswerContainer> which depends on userInfo
        // No nonCodable in userInfo
        let nonCodableDictionary = ["A": NonCodableContainer (label:"A", nonCodable: nonCodable), "B" : NonCodableContainer (label:"B", nonCodable: nonCodable)]
        do {
            document = try encoder.encode(nonCodableDictionary)
        } catch {
            XCTFail ("Expected success")
        }
        decoder = BSONDecoder()
        do {
            let _ = try decoder.decode(Dictionary<String, NonCodableContainer>.self, from: document)
            XCTFail ("Expected error")
        } catch NonCodableError.noNonCodable {} catch {
            XCTFail ("Expected NonCodableError.noNonCodable but got \(error)")
        }
        decoder = BSONDecoder(userInfo: nil)
        do {
            let _ = try decoder.decode(Dictionary<String, NonCodableContainer>.self, from: document)
            XCTFail ("Expected error")
        } catch NonCodableError.noNonCodable {} catch {
            XCTFail ("Expected NonCodableError.noNonCodable but got \(error)")
        }
        decoder = BSONDecoder(userInfo: [:])
        do {
            let _ = try decoder.decode(Dictionary<String, NonCodableContainer>.self, from: document)
            XCTFail ("Expected error")
        } catch NonCodableError.noNonCodable {} catch {
            XCTFail ("Expected NonCodableError.noNonCodable but got \(error)")
        }
        // userInfo contains nonCodable
        decoder = BSONDecoder(userInfo: userInfo)
        do {
            let decodedDictionary = try decoder.decode(Dictionary<String, NonCodableContainer>.self, from: document)
            XCTAssertEqual (2, decodedDictionary.count)
            XCTAssertEqual ("A", decodedDictionary["A"]!.label)
            XCTAssertTrue (decodedDictionary["A"]!.nonCodable === nonCodable)
            XCTAssertEqual ("B", decodedDictionary["B"]!.label)
            XCTAssertTrue (decodedDictionary["B"]!.nonCodable === nonCodable)
        } catch {
            XCTFail ("Expected success but got \(error)")
        }
        // Test Decoding of Set<AnswerContainer> which depends on userInfo
        // No nonCodable in userInfo
        let nonCodableSet: Set<NonCodableContainer> = [NonCodableContainer (label:"A", nonCodable: nonCodable), NonCodableContainer (label:"B", nonCodable: nonCodable)]
        do {
            document = try encoder.encode(nonCodableSet)
        } catch {
            XCTFail ("Expected success")
        }
        decoder = BSONDecoder()
        do {
            let _ = try decoder.decode(Dictionary<String, NonCodableContainer>.self, from: document)
            XCTFail ("Expected error")
        } catch NonCodableError.noNonCodable {} catch {
            XCTFail ("Expected NonCodableError.noNonCodable but got \(error)")
        }
        decoder = BSONDecoder(userInfo: nil)
        do {
            let _ = try decoder.decode(Dictionary<String, NonCodableContainer>.self, from: document)
            XCTFail ("Expected error")
        } catch NonCodableError.noNonCodable {} catch {
            XCTFail ("Expected NonCodableError.noNonCodable but got \(error)")
        }
        decoder = BSONDecoder(userInfo: [:])
        do {
            let _ = try decoder.decode(Dictionary<String, NonCodableContainer>.self, from: document)
            XCTFail ("Expected error")
        } catch NonCodableError.noNonCodable {} catch {
            XCTFail ("Expected NonCodableError.noNonCodable but got \(error)")
        }
        // userInfo contains nonCodable
        decoder = BSONDecoder(userInfo: userInfo)
        do {
            let decodedSet = try decoder.decode(Set<NonCodableContainer>.self, from: document)
            XCTAssertEqual (2, decodedSet.count)
            for nonCodableContainer in decodedSet {
                XCTAssertTrue (nonCodableContainer.label == "A" || nonCodableContainer.label == "B")
                XCTAssertTrue (nonCodableContainer.nonCodable === nonCodable)
            }
        } catch {
            XCTFail ("Expected success but got \(error)")
        }
    }
    
    // Does BSONEncoder pass userInfo back up the encoding tree
    public func testUserInfoRoundTrip() throws {
        
        struct CodableStruct : Codable {
            
            let s1 = "1"
            let s2 = "2"
        }
        
        class ThreeAttributeContainer : Codable {
            
            init (a1: NonCodableContainer, a2: CodableStruct, a3: NonCodableContainer) {
                self.a1 = a1
                self.a2 = a2
                self.a3 = a3
            }
            
            let a1: NonCodableContainer
            let a2: CodableStruct
            let a3: NonCodableContainer
            
        }
        
        let nonCodable = NonCodable()
        let nc1 = NonCodableContainer (label: "1", nonCodable: nonCodable)
        let c1 = CodableStruct()
        let nc2 = NonCodableContainer (label: "2", nonCodable: nonCodable)
        let userInfo: [CodingUserInfoKey : Any] = [NonCodableContainer.nonCodableKey : nonCodable]
        let tripleContainer = ThreeAttributeContainer (a1: nc1, a2: c1, a3: nc2)
        let encoder = BSONEncoder()
        let document = try encoder.encode(tripleContainer)
        let decoder = BSONDecoder (userInfo: userInfo)
        let decodedTripleContainer = try decoder.decode(ThreeAttributeContainer.self, from: document)
        XCTAssertEqual ("1", decodedTripleContainer.a1.label)
        XCTAssertTrue (decodedTripleContainer.a1.nonCodable === nonCodable)
        XCTAssertEqual ("1", decodedTripleContainer.a2.s1)
        XCTAssertEqual ("2", decodedTripleContainer.a2.s2)
        XCTAssertEqual ("2", decodedTripleContainer.a3.label)
        XCTAssertTrue (decodedTripleContainer.a3.nonCodable === nonCodable)
    }
    
// See https://github.com/OpenKitten/BSON/issues/43
//    func testEmptyCodable() {
//
//        class EmptyCodable : Codable {}
//        let encoder = BSONEncoder()
//        let decoder = BSONDecoder()
//        var document = Document()
//        let emptySource = EmptyCodable()
//        do {
//            document = try encoder.encode(emptySource)
//        } catch {
//            XCTFail ("Expected success but got \(error)")
//        }
//        do {
//            let _ = try decoder.decode(EmptyCodable.self, from: document)
//        } catch {
//            XCTFail ("Expected success \(error)")
//        }
//        let arrayOfEmptySource = [EmptyCodable(), EmptyCodable()]
//        do {
//            document = try encoder.encode(arrayOfEmptySource)
//        } catch {
//            XCTFail ("Expected success but got \(error)")
//        }
//        // JSONEncoder and JSONDecoder can handle this
//        do {
//            let jsonEncoder = JSONEncoder()
//            let data = try jsonEncoder.encode(arrayOfEmptySource)
//            let jsonDecoder = JSONDecoder()
//            let decodedArray = try jsonDecoder.decode ([EmptyCodable].self, from: data)
//            XCTAssertEqual (2, decodedArray.count)
//        } catch {
//            XCTFail ("Expected success but got \(error)")
//        }
//    }
    
}

// Consructs used for testUserInfo

fileprivate class NonCodable{}

fileprivate enum NonCodableError : Error {
    case noNonCodable
}

fileprivate class NonCodableContainer : Codable, Hashable {
    
    enum CodingKeys: String, CodingKey {
        case label
    }
    
    init (label: String, nonCodable: NonCodable) {
        self.label = label
        self.nonCodable = nonCodable
    }
    
    required public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        label = try values.decode(String.self, forKey: .label)
        if let nonCodable = decoder.userInfo[NonCodableContainer.nonCodableKey] as? NonCodable {
            self.nonCodable = nonCodable
        } else {
            throw NonCodableError.noNonCodable
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(label, forKey: .label)
    }
    
    var hashValue: Int {
        return label.hashValue
    }
    
    let nonCodable: NonCodable
    let label: String
    
    static let nonCodableKey: CodingUserInfoKey = CodingUserInfoKey (rawValue: "nonCodableKey")!
}

extension NonCodableContainer : Equatable {
    static func == (lhs: NonCodableContainer, rhs: NonCodableContainer) -> Bool {
        return lhs.label == rhs.label && lhs.nonCodable === rhs.nonCodable
    }
}

#endif


