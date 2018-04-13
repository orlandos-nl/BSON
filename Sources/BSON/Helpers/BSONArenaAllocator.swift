/// A single buffer arena that is allocated by the allocator
fileprivate struct BSONArena {
    let buffer: UnsafeMutableBufferPointer<UInt8>
    var used: [Bool]
    let blockSize: Int
    var blockCount: Int
    
    /// Creates a new BSONArena buffer
    fileprivate init(blockCount: Int, blockSize: Int) {
        self.blockCount = blockCount
        self.blockSize = blockSize
        self.buffer = UnsafeMutableBufferPointer<UInt8>.allocate(capacity: blockCount * blockSize)
        self.used = [Bool](repeating: false, count: blockCount)
    }
    
    /// Reserves `count` concecutive blocks with `blockSize` bytes per block
    func reserveBlocks(count: Int) -> CountableRange<BSONArenaBlock>? {
        var possibleOrigin: Int?
        var concecutive = 0
        var range: CountableRange<BSONArenaBlock>?
        var foundOrigin: (start: Int, length: Int)?
        
        func flushOrigin() {
            // If a possible origin was found
            if let possibleOrigin = possibleOrigin {
                // If the count matches exactly
                if concecutive == count {
                    // Set the range ready to be returned
                    range = BSONArenaBlock(index: possibleOrigin)..<BSONArenaBlock(index: possibleOrigin &+ count)
                    // Otherwise, we may have a better match
                } else if concecutive > count {
                    // If a previous (low) count has been found
                    if let _foundOrigin = foundOrigin {
                        // If this count is more efficient
                        if _foundOrigin.length > concecutive {
                            // Use this count as the new standard
                            foundOrigin = (possibleOrigin, concecutive)
                            // If this count is equally efficient
                        } else if _foundOrigin.length == concecutive {
                            foundOrigin = (possibleOrigin, concecutive)
                        }
                    } else {
                        foundOrigin = (possibleOrigin, concecutive)
                    }
                }
            }
        }
        
        // Loop over all blocks, looking for connections
        for i in 0..<blockCount {
            // If it's already used, this block is unusable
            if used[i] {
                // Flush the found group of entities
                flushOrigin()
                
                // Reset the consecutive state
                concecutive = 0
                possibleOrigin = nil
            } else {
                // Increase the concecutive count
                concecutive = concecutive &+ 1
                
                // If no origin was set yet, set it now
                if possibleOrigin == nil {
                    possibleOrigin = i
                }
            }
            
            // If an ideal range was found, return it
            if let range = range {
                return range
            }
        }
        
        // Flush the state, hopefully finding something useful
        flushOrigin()
        
        // If an ideal range was found, return it
        if let range = range {
            return range
        }
        
        // Take the next best thing
        if let foundOrigin = foundOrigin {
            return BSONArenaBlock(index: foundOrigin.start) ..< BSONArenaBlock(index: foundOrigin.start &+ foundOrigin.length)
        }
        
        return nil
    }
    
    fileprivate func storage(
        in range: CountableRange<BSONArenaBlock>,
        arenaId: BSONArenaIdentifier,
        allocator: BSONArenaAllocator
    ) -> AutoDeallocatingStorage {
        let slice = BSONArenaAllocatorSlice(
            allocator: allocator,
            arena: arenaId,
            range: range
        )
        
        let buffer = UnsafeMutableBufferPointer(
            start: self.buffer.baseAddress?.advanced(by: range.startIndex.index * blockSize),
            count: range.count &* blockSize
        )
        
        return AutoDeallocatingStorage(
            buffer: buffer,
            method: .return(slice)
        )
    }
}

public final class BSONArenaAllocator {
    let blockSize: Int
    let blockCount: Int
    fileprivate var arenas = [BSONArena]()
    
    public init(blocks: Int, blockSize: Int) {
        self.blockSize = blockSize
        self.blockCount = blocks
    }
    
    internal func reserve(minimumCapacity: Int) -> AutoDeallocatingStorage {
        return self.reserve(size: (minimumCapacity / blockSize) &+ 1)
    }
    
    fileprivate func reserve(size: Int) -> AutoDeallocatingStorage {
        guard size <= blockCount else {
            return AutoDeallocatingStorage(size: size * blockSize)
        }
        
        // Try all arenas
        nextArena: for arena in 0..<arenas.count {
            let blocksNeeded = (size / blockSize) &+ ((size & blockSize > 0) ? 1 : 0)
            
            guard let range = arenas[arena].reserveBlocks(count: blocksNeeded) else {
                continue nextArena
            }
            
            return arenas[arena].storage(
                in: range,
                arenaId: BSONArenaIdentifier(index: arena),
                allocator: self
            )
        }
        
        // Create a new arena because no other arenas had space
        let arenaId = arenas.count
        let arena = BSONArena(blockCount: blockCount, blockSize: blockSize)
        arenas.append(arena)
        
        // If this fails it's a big user error
        guard let range = arena.reserveBlocks(count: size) else {
            return AutoDeallocatingStorage(size: size * blockSize)
        }
        
        return arena.storage(
            in: range,
            arenaId: BSONArenaIdentifier(index: arenaId),
            allocator: self
        )
    }
    
    /// Returns the blocks to the arena
    fileprivate func `return`(
        range blockRange: CountableRange<BSONArenaBlock>,
        in arena: BSONArenaIdentifier
    ) {
        for i in blockRange {
            arenas[arena.index].used[i.index] = false
        }
    }
    
    deinit {
        for arena in arenas {
            arena.buffer.deallocate()
        }
    }
}

/// An identifier for a specific block within an arena buffer
fileprivate struct BSONArenaBlock: Strideable {
    func distance(to other: BSONArenaBlock) -> Int {
        return index.distance(to: other.index)
    }
    
    func advanced(by n: Int) -> BSONArenaBlock {
        return BSONArenaBlock(index: index.advanced(by: n))
    }
    
    fileprivate let index: Int
    
    fileprivate init(index: Int) {
        self.index = index
    }
}

/// An identifier for the internal arena buffer
fileprivate struct BSONArenaIdentifier {
    fileprivate let index: Int
    
    fileprivate init(index: Int) {
        self.index = index
    }
}

/// A slice of data from an allocator
///
/// Used as a reference point for BSONBuffer
struct BSONArenaAllocatorSlice {
    fileprivate let allocator: BSONArenaAllocator
    fileprivate var range: CountableRange<BSONArenaBlock>
    fileprivate var arena: BSONArenaIdentifier
    
    fileprivate init(
        allocator: BSONArenaAllocator,
        arena: BSONArenaIdentifier,
        range: CountableRange<BSONArenaBlock>
    ) {
        self.allocator = allocator
        self.range = range
        self.arena = arena
    }
    
    func `return`() {
        allocator.return(range: range, in: arena)
    }
}
