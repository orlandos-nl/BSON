import Foundation

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
    
    let storage: ByteBuffer
    
    public init() {
        self.storage = .init(bytes: [SubType.generic.identifier])
    }
    
    internal init(storage: BSONBuffer) {
        self.storage = storage
    }
    
    public init(pointer: UnsafePointer<UInt8>, count: Int) {
        var storage = BSONBuffer(size: count &+ 1)
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
