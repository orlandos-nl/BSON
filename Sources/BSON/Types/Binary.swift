import Foundation
import NIO

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
    
    /// A single byte indicating the data type
    public var subType: SubType
    
    /// The underlying data storage of the Binary instance
    public private(set) var storage: ByteBuffer
    
    /// The data stored
    public var data: Data {
        get {
            return storage.withUnsafeReadableBytes(Data.init)
        }
        set {
            storage = Document.allocator.buffer(capacity: newValue.count)
            storage.write(bytes: newValue)
        }
    }
    
    /// Initializes a new Binary from the given ByteBuffer
    ///
    /// - parameter buffer: The ByteBuffer to use as storage. The buffer will be sliced.
    init(subType: SubType = .generic, buffer: ByteBuffer) {
        self.subType = subType
        self.storage = buffer.slice()
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
            self.storage.write(bytes: data)
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        try self.data.encode(to: encoder)
    }
    
    /// The amount of data, in bytes, stored in this Binary
    public var count: Int {
        return storage.readableBytes
    }
}
