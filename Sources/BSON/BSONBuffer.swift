import Foundation

/// A high performance, auto-deallocating, slicable and CoW binary data store
struct Storage {
    /// The internal storage type
    private indirect enum _Storage {
        /// SubStorages are a slice of a super storage, slicing it's contents
        ///
        /// Sub-Storages are copied on write
        case subStorage(_Storage, range: Range<Int>)
        
        /// Read-only buffers will be copied when a mutation occurs
        case readOnly(UnsafeBufferPointer<UInt8>)
        
        /// Read-Write buffers will modify the existing buffer if unique or copy otherwise
        case readWrite(AutoDeallocatingStorage)
        
        /// The amount of bytes within this storage
        var count: Int {
            switch self {
            case .subStorage(_, let range):
                return range.count
            case .readOnly(let buffer):
                return buffer.count
            case .readWrite(let storage):
                return storage.buffer.count
            }
        }
        
        var readBuffer: UnsafeBufferPointer<UInt8> {
            switch self {
            case .subStorage(let storage, let range):
                let buffer = storage.readBuffer
                
                let pointer = buffer.baseAddress!.advanced(by: range.lowerBound)
                
                return UnsafeBufferPointer(start: pointer, count: range.count)
            case .readOnly(let buffer):
                return buffer
            case .readWrite(let storage):
                return UnsafeBufferPointer(
                    start: storage.buffer.baseAddress,
                    count: storage.buffer.count
                )
            }
        }
        
        var writeBuffer: UnsafeMutableBufferPointer<UInt8>? {
            switch self {
            case .readWrite(let storage):
                return storage.buffer
            case .subStorage(let storage, let range):
                guard let buffer = storage.writeBuffer else {
                    return nil
                }
                
                let pointer = buffer.baseAddress!.advanced(by: range.lowerBound)
                
                return UnsafeMutableBufferPointer(start: pointer, count: range.count)
            default:
                return nil
            }
        }
        
        var requiresCopyForMutation: Bool {
            switch self {
            case .readWrite(var storage):
                return isKnownUniquelyReferenced(&storage)
            case .readOnly(_):
                return true
            case .subStorage(let storage, _):
                return storage.requiresCopyForMutation
            }
        }
        
        fileprivate init(size: Int) {
            let pointer = UnsafeMutablePointer<UInt8>.allocate(capacity: size)
            let buffer = UnsafeMutableBufferPointer(start: pointer, count: size)
            
            self = .readWrite(.init(buffer: buffer))
        }
        
        mutating func ensureMutableCapacity(of capacity: Int) {
            func makeCopy(withCapacity capacity: Int) {
                let storage = _Storage(size: capacity)
                storage.writeBuffer!.baseAddress!.assign(from: self.readBuffer.baseAddress!, count: self.count)
                self = storage
            }
            
            let newCapacity = self.count &+ capacity
            
            guard requiresCopyForMutation else {
                makeCopy(withCapacity: newCapacity)
                return
            }
            
            if self.count >= capacity {
                return
            }
            
            switch self {
            case .readWrite(let storage):
                let pointer = realloc(storage.buffer.baseAddress!, newCapacity)!.assumingMemoryBound(to: UInt8.self)
                self = .readWrite(.init(buffer: .init(start: pointer, count: newCapacity)))
            case .subStorage(let storage, let range):
                makeCopy(withCapacity: range.count)
                self.writeBuffer!.baseAddress?.assign(from: storage.readBuffer.baseAddress!, count: range.count)
            case .readOnly(_):
                makeCopy(withCapacity: self.count)
            }
        }
    }
    
    /// A wrapper around a `_Storage` engine enum
    ///
    /// Automatically deallocates writable buffers
    final class AutoDeallocatingStorage {
        var buffer: UnsafeMutableBufferPointer<UInt8>
        
        init(buffer: UnsafeMutableBufferPointer<UInt8>) {
            self.buffer = buffer
        }
        
        deinit {
            buffer.baseAddress?.deallocate()
        }
    }
    
    var readBuffer: UnsafeBufferPointer<UInt8> {
        return UnsafeBufferPointer(start: self.storage.readBuffer.baseAddress, count: usedCapacity)
    }
    
    var writeBuffer: UnsafeMutableBufferPointer<UInt8>? {
        return self.storage.writeBuffer
    }
            
    /// The used capacity is the amount of capacity that's actively occupied
    ///
    /// Unused capacity is located after the used capacity and provide no guarantees for content
    var usedCapacity: Int
    
    /// Max capacity is the amount of capacity that's available before reallocation is necessary
    var maxCapacity: Int {
        return storage.count
    }
    
    /// The underlying automatically deallocating storage engine
    private var storage: _Storage
    
    private init(storage: _Storage) {
        self.storage = storage
        self.usedCapacity = storage.count
    }
    
    init(size: Int) {
        self.storage = .init(size: size)
        self.usedCapacity = 0
    }
    
    init(data: Data) {
        let size = data.count
        let storage = _Storage(size: size)
        
        data.withUnsafeBytes { (pointer: UnsafePointer<UInt8>) in
            storage.writeBuffer!.baseAddress!.assign(from: pointer, count: size)
        }
        
        self.init(storage: storage)
    }
    
    init(bytes: [UInt8]) {
        let size = bytes.count
        let storage = _Storage(size: size)
        
        storage.writeBuffer!.baseAddress!.assign(from: bytes, count: size)
        
        self.init(storage: storage)
    }
    
    init(buffer: UnsafeBufferPointer<UInt8>) {
        self.init(storage: .readOnly(buffer))
    }
    
    init(buffer: UnsafeMutableBufferPointer<UInt8>) {
        self.init(storage: .readWrite(.init(buffer: buffer)))
    }
    
    mutating func insert(at position: Int, from pointer: UnsafePointer<UInt8>, length: Int) {
        self.storage.ensureMutableCapacity(of: self.usedCapacity &+ length)
        
        let writePointer = self.writeBuffer!.baseAddress!
        let insertPointer = writePointer + position
        
        memmove(writePointer + (position + length), insertPointer, length)
        memcpy(insertPointer, pointer, length)
        self.usedCapacity = self.usedCapacity &+ length
    }
    
    mutating func replace(offset: Int, replacing: Int, with pointer: UnsafePointer<UInt8>, length: Int) {
        let diff = replacing &- length
        
        self.storage.ensureMutableCapacity(of: self.usedCapacity &+ length)
        
        let writePointer = self.writeBuffer!.baseAddress!
        let insertPointer = writePointer + offset
        
        if diff > 0 {
            memmove(writePointer + replacing + diff, writePointer + replacing, self.usedCapacity &- offset &- diff)
        }
        
        memcpy(insertPointer, pointer, length)
        self.usedCapacity = self.usedCapacity &+ diff
    }
    
    mutating func append(from pointer: UnsafePointer<UInt8>, length: Int) {
        self.storage.ensureMutableCapacity(of: self.usedCapacity &+ length)
        
        self.writeBuffer?.baseAddress?.advanced(by: self.usedCapacity).assign(from: pointer, count: length)
        self.usedCapacity = self.usedCapacity &+ length
    }
    
    mutating func append(_ byte: UInt8) {
        self.storage.ensureMutableCapacity(of: self.usedCapacity &+ 1)
        
        (self.writeBuffer!.baseAddress! + self.usedCapacity).pointee = byte
        self.usedCapacity = self.usedCapacity &+ 1
    }
    
    mutating func append(_ bytes: [UInt8]) {
        let size = bytes.count
        self.storage.ensureMutableCapacity(of: self.usedCapacity &+ size)
        
        (self.writeBuffer!.baseAddress! + self.usedCapacity).assign(from: bytes, count: size)
        self.usedCapacity = self.usedCapacity &+ size
    }
    
    mutating func remove(from offset: Int, length: Int) {
        memmove(
            self.writeBuffer!.baseAddress! + (offset - length),
            self.writeBuffer!.baseAddress! + offset,
            self.usedCapacity &- offset
        )
        
        self.usedCapacity = self.usedCapacity &- length
    }
    
    subscript(range: Range<Int>) -> Storage {
        return Storage(storage: .subStorage(self.storage, range: range))
    }
}
