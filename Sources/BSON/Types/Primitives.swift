import Foundation

public protocol Primitive: Codable, PrimitiveConvertible {}

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
        buffer.writeBytes(self)
        return Binary(buffer: buffer)
    }
}

extension Document: BSONDataType {
    public func encode(to encoder: Encoder) throws {
        if let encoder = encoder as? AnyBSONEncoder {
            try encoder.encode(document: self)
        } else if self.isArray {
            var container = encoder.unkeyedContainer()
            
            for value in self.values {
                try container.encode(AnyEncodable(encodable: value))
            }
        } else {
            var container = encoder.container(keyedBy: CustomKey.self)
            
            for pair in self.pairs {
                try container.encode(AnyEncodable(encodable: pair.value), forKey: CustomKey(stringValue: pair.key)!)
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

extension Date: BSONDataType {
    init(primitive: Primitive?) throws {
        guard let value = primitive as? Date else {
            throw BSONTypeConversionError(from: type(of: primitive), to: Date.self)
        }
        
        self = value
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
            self = try ObjectId.make(from: string)
        }
    }
}

struct BSONComparisonTypeMismatch: Error {
    let lhs: Primitive?
    let rhs: Primitive?
}

extension Int32: Primitive {}
extension Date: Primitive {}

#if (arch(i386) || arch(arm)) && BSONInt64Primitive
internal typealias _BSON64BitInteger = Int64
extension Int64: Primitive {}
#else
internal typealias _BSON64BitInteger = Int
extension Int: Primitive {}
#endif

extension Double: Primitive {}
extension Bool: Primitive {}
extension String: Primitive {}

public struct MinKey: Primitive {
    public init() {}
}

public struct MaxKey: Primitive {
    public init() {}
}
