import Foundation

/// A wrapper around a `_Storage` engine enum
///
/// Automatically deallocates writable buffers
final class AutoDeallocatingStorage {
    var buffer: UnsafeMutableBufferPointer<UInt8>
    let method: DeallocationMethod
    
    enum DeallocationMethod {
        case `return`(BSONArenaAllocatorSlice)
        case deallocate
    }
    
    init(
        buffer: UnsafeMutableBufferPointer<UInt8>,
        method: DeallocationMethod = .deallocate
    ) {
        self.buffer = buffer
        self.method = method
    }
    
    init(size: Int) {
        self.buffer = UnsafeMutableBufferPointer<UInt8>.allocate(capacity: size)
        self.method = .deallocate
    }
    
    deinit {
        switch method {
        case .deallocate:
            buffer.baseAddress?.deallocate()
        case .return(let allocatorMetadata):
            allocatorMetadata.return()
        }
    }
}

/// A high performance, auto-deallocating, slicable and CoW binary data store
struct BSONBuffer {
    /// The internal storage type
    private indirect enum Storage {
        /// SubStorages are a slice of a super storage, slicing it's contents
        ///
        /// Sub-Storages are copied on write
        case subStorage(Storage, range: Range<Int>)
        
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
                // FIXME: Always `true` thanks to `var storage`
                return isKnownUniquelyReferenced(&storage)
            case .readOnly(_):
                return true
            case .subStorage(let storage, _):
                return storage.requiresCopyForMutation
            }
        }
        
        fileprivate init(size: Int) {
            self = .readWrite(.init(size: size))
        }
        
        /// Ensures buffer mutability as well as the availability of a minimum amount of bytes of `capacity`
        mutating func ensureMutableCapacity(of newCapacity: Int) {
            func makeCopy(withCapacity capacity: Int) {
                let storage = Storage(size: capacity)
                storage.writeBuffer!.baseAddress!.assign(from: self.readBuffer.baseAddress!, count: self.count)
                self = storage
            }
            
            guard requiresCopyForMutation else {
                makeCopy(withCapacity: newCapacity)
                return
            }
            
            // Don't shrink
            if newCapacity <= self.count {
                return
            }
            
            switch self {
            case .readWrite(let storage):
                // FIXME: Crashes on release?
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
    
    /// Provides a read-only view into the current data
    ///
    /// Only reflects the used capacity
    var readBuffer: UnsafeBufferPointer<UInt8> {
        return UnsafeBufferPointer(start: self.storage.readBuffer.baseAddress, count: usedCapacity)
    }
    
    /// Provides a read-write view into the current data buffer
    ///
    /// Reflects both used and unused capacity and should be used together with the `usedCapacity` property
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
    private var storage: Storage
    
    /// Wraps a `Storage` assuming the entire storage is used capacity
    private init(storage: Storage) {
        self.storage = storage
        self.usedCapacity = storage.count
    }
    
    /// Wraps a `AutoDeallocatingStorage` assuming the entire storage is unused capacity
    public init(allocating: Int, allocator: BSONArenaAllocator) {
        self.storage = .readWrite(allocator.reserve(minimumCapacity: allocating))
        self.usedCapacity = 0
    }
    
    /// Creates a new storage buffer of the given size
    init(size: Int) {
        self.storage = .init(size: size)
        self.usedCapacity = 0
    }
    
    /// Creates a new storage buffer, copying the provided `Data` buffer
    init(data: Data) {
        let size = data.count
        let storage = Storage(size: size)
        
        data.withUnsafeBytes { (pointer: UnsafePointer<UInt8>) in
            storage.writeBuffer!.baseAddress!.assign(from: pointer, count: size)
        }
        
        self.init(storage: storage)
    }
    
    /// Creates a new storage buffer, copying the provided `[UInt8]` buffer
    init(bytes: [UInt8]) {
        let size = bytes.count
        let storage = Storage(size: size)
        
        storage.writeBuffer!.baseAddress!.assign(from: bytes, count: size)
        
        self.init(storage: storage)
    }
    
    /// Wraps the provided buffer pointer as a read-only view
    ///
    /// This view must NOT be deallocated for the duration of this buffer's lifetime
    init(buffer: UnsafeBufferPointer<UInt8>) {
        self.init(storage: .readOnly(buffer))
    }
    
    /// Wraps the provided buffer pointer as a read-write view
    ///
    /// This view must NOT be deallocated for the duration of this buffer's lifetime
    init(buffer: UnsafeMutableBufferPointer<UInt8>) {
        self.init(storage: .readWrite(.init(buffer: buffer)))
    }
    
    /// Inserts the contents of `pointer` with the `length` in bytes at offset `position`
    mutating func insert(at position: Int, from pointer: UnsafePointer<UInt8>, length: Int) {
        self.storage.ensureMutableCapacity(of: self.usedCapacity &+ length)
        
        let writePointer = self.writeBuffer!.baseAddress!
        let insertPointer = writePointer + position
        
        memmove(writePointer + (position + length), insertPointer, length)
        memcpy(insertPointer, pointer, length)
        self.usedCapacity = self.usedCapacity &+ length
    }
    
    /// Ensures a total of `n` bytes are available for writing
    public mutating func ensureCapacity(_ n: Int) {
        self.storage.ensureMutableCapacity(of: n)
    }
    
    /// Replaces `replacing` bytes at the `offset`
    ///
    /// The replacement will be read from `pointer` and the provided `length`
    ///
    /// Attempts to do a drop-in replacement with as little effort possible.
    ///
    /// Automatically reallocs for the new data to fit if necessary
    mutating func replace(offset: Int, replacing: Int, with pointer: UnsafePointer<UInt8>, length: Int) {
        let diff = replacing &- length
        
        self.storage.ensureMutableCapacity(of: self.usedCapacity &+ diff)
        
        let writePointer = self.writeBuffer!.baseAddress!
        let insertPointer = writePointer + offset
        
        // More data is written than removed
        if diff < 0, usedCapacity > offset &+ replacing {
            let trailingCapacityOffset = offset &+ replacing
            memmove(insertPointer + replacing, insertPointer + length, self.usedCapacity &- trailingCapacityOffset)
        }
        
        memcpy(insertPointer, pointer, length)
        
        // More data is removed than written
        if diff > 0 {
            let replacingPointer = writePointer + replacing
            memmove(replacingPointer + diff, replacingPointer, self.usedCapacity &- offset &- diff)
        }
        
        self.usedCapacity = self.usedCapacity &+ diff
    }
    
    /// Appends the pointer's data to the end of the buffer.
    ///
    /// Automatically reallocs for the new data to fit if necessary
    mutating func append(from pointer: UnsafePointer<UInt8>, length: Int) {
        self.storage.ensureMutableCapacity(of: self.usedCapacity &+ length)
        
        self.writeBuffer?.baseAddress?.advanced(by: self.usedCapacity).assign(from: pointer, count: length)
        self.usedCapacity = self.usedCapacity &+ length
    }
    
    /// Appends the byte
    ///
    /// Automatically reallocs for the new data to fit if necessary
    mutating func append(_ byte: UInt8) {
        self.storage.ensureMutableCapacity(of: self.usedCapacity &+ 1)
        
        (self.writeBuffer!.baseAddress! + self.usedCapacity).pointee = byte
        self.usedCapacity = self.usedCapacity &+ 1
    }
    
    /// Appends the bytes to the end of the buffer.
    ///
    /// Automatically reallocs for the new data to fit if necessary
    mutating func append(_ bytes: [UInt8]) {
        let size = bytes.count
        self.storage.ensureMutableCapacity(of: self.usedCapacity &+ size)
        
        (self.writeBuffer!.baseAddress! + self.usedCapacity).assign(from: bytes, count: size)
        self.usedCapacity = self.usedCapacity &+ size
    }
    
    /// Removes `length` bytes from the offset position
    ///
    /// The bytes may not be wiped out of memory and can simply become 'unused' capacity
    mutating func remove(from offset: Int, length: Int) {
        memmove(
            self.writeBuffer!.baseAddress! + (offset - length),
            self.writeBuffer!.baseAddress! + offset,
            self.usedCapacity &- offset
        )
        
        self.usedCapacity = self.usedCapacity &- length
    }
    
    /// Creates a sliced substorage with the given range
    subscript(range: Range<Int>) -> BSONBuffer {
        return BSONBuffer(storage: .subStorage(self.storage, range: range))
    }
}
