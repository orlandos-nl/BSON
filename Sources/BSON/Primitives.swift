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
    func decodeBinary() throws -> Binary
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
extension Int: Primitive {}
extension Double: Primitive {}
extension Bool: Primitive {}
extension String: Primitive {}

extension Optional: Primitive where Wrapped: Primitive {}

public struct Binary: Primitive {
    public enum SubType {
        case generic
        case function
        case uuid
        case md5
        case userDefined(UInt8)
        
        init(_ byte: UInt8) {
            switch byte {
            case 0x00: self = .generic
            case 0x01: self = .function
            case 0x04: self = .uuid
            case 0x05: self = .md5
            default: self = .userDefined(byte)
            }
        }
        
        var identifier: UInt8 {
            switch self {
            case .generic: return 0x00
            case .function: return 0x01
            case .uuid: return 0x04
            case .md5: return 0x05
            case .userDefined(let byte): return byte
            }
        }
    }
    
    let storage: Storage
    
    public init() {
        self.storage = .init(bytes: [SubType.generic.identifier])
    }
    
    public init(pointer: UnsafePointer<UInt8>, count: Int) {
        var storage = Storage(size: count &+ 1)
        storage.append(SubType.generic.identifier)
        storage.append(from: pointer, length: count)
        
        self.storage = storage
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let container = container as? AnySingleValueBSONDecodingContainer {
            self = try container.decodeBinary()
        } else {
            let data = try container.decode(Data.self)
            let size = data.count
            
            self = data.withUnsafeBytes { pointer in
                return Binary(pointer: pointer, count: size)
            }
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        try self.makeData().encode(to: encoder)
    }
    
    public var count: Int {
        return self.storage.readBuffer.count &- 1
    }
    
    public var subType: SubType {
        return SubType(self.storage.readBuffer.baseAddress!.pointee)
    }
    
    func makeData() -> Data {
        let pointer = storage.readBuffer.baseAddress!.advanced(by: 1)
        let buffer = UnsafeBufferPointer(start: pointer, count: self.count)
        
        return Data(buffer: buffer)
    }
}
