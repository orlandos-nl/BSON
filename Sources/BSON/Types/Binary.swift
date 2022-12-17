import Foundation
import NIOCore

/// A BSON Binary. This is used for storing binary data in MongoDB
/// See https://docs.mongodb.com/manual/reference/bson-types/#binary
public struct Binary: Primitive, Hashable, @unchecked Sendable {
    public static func == (lhs: Binary, rhs: Binary) -> Bool {
        return lhs.subType.identifier == rhs.subType.identifier && lhs.storage == rhs.storage
    }
    
    public func hash(into hasher: inout Hasher) {
        subType.identifier.hash(into: &hasher)
        storage.withUnsafeReadableBytes { buffer in
            hasher.combine(bytes: buffer)
        }
    }
    
    /// The different types of binary data that can be stored in a Binary instance. The identifier is the byte that is stored in the BSON document.
    /// See https://docs.mongodb.com/manual/reference/bson-types/#binary
    public enum SubType: Sendable {
        /// A generic binary type. The identifier is 0x00.
        case generic

        /// A function type. The identifier is 0x01.
        case function

        /// A UUID type. The identifier is 0x04.
        case uuid

        /// An MD5 type. The identifier is 0x05.
        case md5

        /// A user defined type. The identifier is any byte other than 0x00, 0x01, 0x04, or 0x05.
        case userDefined(UInt8)
        
        /// Initializes a SubType from a byte. If the byte is not a valid identifier, the SubType will be set to .userDefined.
        init(_ byte: UInt8) {
            switch byte {
            case 0x00: self = .generic
            case 0x01: self = .function
            case 0x04: self = .uuid
            case 0x05: self = .md5
            default: self = .userDefined(byte)
            }
        }
        
        /// The byte that represents this SubType
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
    
    /// A single byte indicating the data type
    public var subType: SubType
    
    /// The underlying data storage of the Binary instance
    public private(set) var storage: ByteBuffer
    
    /// The data stored
    public var data: Data {
        get {
            return storage.withUnsafeReadableBytes { buffer in
                let bytes = buffer.bindMemory(to: UInt8.self)
                
                return Data(buffer: bytes)
            }
        }
        set {
            storage = Document.allocator.buffer(capacity: newValue.count)
            storage.writeBytes(newValue)
        }
    }
    
    /// Initializes a new Binary from the given ByteBuffer
    ///
    /// - parameter buffer: The ByteBuffer to use as storage. The buffer will be sliced.
    public init(subType: SubType = .generic, buffer: ByteBuffer) {
        self.subType = subType
        self.storage = buffer
    }
    
    // TODO: Encode / decode the subtype
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let container = container as? AnySingleValueBSONDecodingContainer {
            self = try container.decodeBinary()
        } else {
            let data = try container.decode(Data.self)
            self.subType = .generic
            self.storage = Document.allocator.buffer(capacity: data.count)
            self.storage.writeBytes(data)
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        if encoder is AnyBSONEncoder {
            let container = encoder.singleValueContainer()
            if var container = container as? AnySingleValueBSONEncodingContainer {
                try container.encode(primitive: self)
            } else {
                try self.data.encode(to: encoder)
            }
        } else {
            try self.data.encode(to: encoder)
        }
    }
    
    /// The amount of data, in bytes, stored in this Binary
    public var count: Int {
        return storage.readableBytes
    }
}
