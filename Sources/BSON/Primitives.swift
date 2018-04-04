import Foundation

public protocol Primitive: Codable {}
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
}

internal protocol AnySingleValueBSONEncodingContainer {
    func encode(primitive: Primitive) throws
}

fileprivate struct UnsupportedDocumentDecoding: Error {}

fileprivate struct AnyEncodable: Encodable {
    var encodable: Encodable
    
    func encode(to encoder: Encoder) throws {
        try encodable.encode(to: encoder)
    }
}

extension Document: BSONDataType {
    public func encode(to encoder: Encoder) throws {
        if let encoder = encoder as? AnyBSONEncoder {
            try encoder.encode(document: self)
        } else {
            var container = encoder.container(keyedBy: CustomKey.self)
            
            for pair in self {
                try container.encode(AnyEncodable(encodable: pair.value), forKey: CustomKey(stringValue: pair.key)!)
            }
        }
    }
    
    public init(from decoder: Decoder) throws {
        if let decoder = decoder as? AnySingleValueBSONDecodingContainer {
            self = try decoder.decodeDocument()
            return
        }
        
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

public struct Document: Primitive {
    var storage: Storage
    var nullTerminated: Bool
    var cache = DocumentCache()
    
    init() {
        self.init(bytes: [5, 0, 0, 0])
        self.nullTerminated = false
    }
    
    init(storage: Storage, nullTerminated: Bool) {
        self.storage = storage
        self.nullTerminated = nullTerminated
    }
    
    public init(data: Data) {
        self.storage = Storage(data: data)
        self.nullTerminated = true
    }
    
    public init(bytes: [UInt8]) {
        self.storage = Storage(bytes: bytes)
        self.nullTerminated = true
    }
    
    public init(buffer: UnsafeBufferPointer<UInt8>) {
        self.storage = Storage(buffer: buffer)
        self.nullTerminated = true
    }
}

extension ObjectId: Primitive {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        if let container = container as? AnySingleValueBSONEncodingContainer {
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
extension Int32: Primitive {}
extension Int64: Primitive {}
extension Double: Primitive {}
extension Bool: Primitive {}
extension String: Primitive {}

extension Optional: Primitive where Wrapped: Primitive {}
