import Foundation

public protocol Primitive: Codable, PrimitiveConvertible {}

// TODO: Investigate if this protocol is needed
internal protocol BSONDataType: Primitive {
    var primitive: Primitive { get }
    init(primitive: Primitive?) throws
}

extension BSONDataType {
    var primitive: Primitive { return self }
}

internal protocol AnyBSONEncoder {
    func encode(document: Document) throws
}

internal protocol AnySingleValueBSONDecodingContainer {
    func decodeObjectId() throws -> ObjectId
    func decodeDocument() throws -> Document
    func decodeDecimal128() throws -> Decimal128
    func decodeBinary() throws -> Binary
    func decodeRegularExpression() throws -> RegularExpression
    func decodeNull() throws -> Null
}

internal protocol AnySingleValueBSONEncodingContainer {
    mutating func encode(primitive: Primitive) throws
}

fileprivate struct UnsupportedDocumentDecoding: Error {}

fileprivate struct AnyEncodable: Encodable {
    var encodable: Encodable
    
    func encode(to encoder: Encoder) throws {
        try encodable.encode(to: encoder)
    }
}

extension Data: BSONDataType {
    init(primitive: Primitive?) throws {
        guard let value = primitive, let binary = value as? Binary else {
            throw BSONTypeConversionError(from: type(of: primitive), to: Data.self)
        }
        
        self = binary.data
    }
    
    var primitive: Primitive {
        var buffer = Document.allocator.buffer(capacity: self.count)
        buffer.writeWithUnsafeMutableBytes { writer in
            let writer = writer.bindMemory(to: UInt8.self)
            let size = self.count
            return self.withUnsafeBytes { (reader: UnsafePointer<UInt8>) in
                writer.baseAddress!.initialize(from: reader, count: size)
                
                return size
            }
        }
        
        return Binary(buffer: buffer)
    }
}

extension Document: BSONDataType {
    public func encode(to encoder: Encoder) throws {
        if let encoder = encoder as? AnyBSONEncoder {
            try encoder.encode(document: self)
        } else {
            switch self.isArray {
            case true:
                var container = encoder.unkeyedContainer()
                
                for value in self.values {
                    try container.encode(AnyEncodable(encodable: value))
                }
            case false:
                var container = encoder.container(keyedBy: CustomKey.self)
                
                for pair in self.pairs {
                    try container.encode(AnyEncodable(encodable: pair.value), forKey: CustomKey(stringValue: pair.key)!)
                }
            }
        }
    }
    
    public init(from decoder: Decoder) throws {
        if let decoder = decoder as? AnySingleValueBSONDecodingContainer {
            self = try decoder.decodeDocument()
            return
        }
        
        // TODO: Implement decoding a document from a non-BSON decoder
        // TODO: Replace this with a central BSON decoding error type
        throw UnsupportedDocumentDecoding()
    }
    
    init(primitive: Primitive?) throws {
        guard let document = primitive as? Document else {
            throw BSONTypeConversionError(from: primitive, to: Document.self)
        }
        
        self = document
    }
}

fileprivate struct CustomKey: CodingKey {
    var stringValue: String
    
    init?(stringValue: String) {
        self.stringValue = stringValue
    }
    
    var intValue: Int?
    
    init?(intValue: Int) {
        self.intValue = intValue
        self.stringValue = intValue.description
    }
}

extension ObjectId: Primitive {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        if var container = container as? AnySingleValueBSONEncodingContainer {
            try container.encode(primitive: self)
        } else {
            try container.encode(self.hexString)
        }
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let container = container as? AnySingleValueBSONDecodingContainer {
            self = try container.decodeObjectId()
        } else {
            let string = try container.decode(String.self)
            try self.init(string)
        }
    }
}

//public func ==(lhs: Primitive?, rhs: Primitive?) -> Bool {
//    guard let lhs = lhs else {
//        if case .none = rhs {
//            return true
//        }
//        return false
//    }
//    
//    guard let rhs = rhs else {
//        return false
//    }
//    
//    return [lhs] as Document == [rhs] as Document
//}
//
//extension Collection where Element == Primitive {
//    public static func ==(lhs: Self, rhs: Self) -> Bool {
//        guard lhs.count == rhs.count else {
//            return false
//        }
//
//        for set in zip(lhs, rhs) {
//            guard set.0 == set.1 else {
//                return false
//            }
//        }
//
//        return true
//    }
//}

extension Int32: Primitive {}
extension Date: Primitive {}
extension Int: Primitive {}
extension Double: Primitive {}
extension Bool: Primitive {}
extension String: Primitive {}

public struct MinKey: Primitive {
    public init() {}
}

public struct MaxKey: Primitive {
    public init() {}
}
