import Foundation

struct IndexKey: Hashable {
    let data: Data
    
    var hashValue: Int {
        return data.hashValue
    }
    
    /// Initializes it from binary
    public init(_ data: Data) {
        self.data = data
    }
    
    static func ==(lhs: IndexKey, rhs: IndexKey) -> Bool {
        guard lhs.data.count == rhs.data.count else {
            return false
        }
        
        return lhs.data.withUnsafeBytes { (lhsPointer: UnsafePointer<UInt8>) in
            return rhs.data.withUnsafeBytes { (rhsPointer: UnsafePointer<UInt8>) in
                return memcmp(lhsPointer, rhsPointer, lhs.data.count) == 0
            }
        }
    }
    
    var s: String {
        return String(data: data, encoding: .utf8)!
    }
    
    public static func <(lhs: IndexKey, rhs: IndexKey) -> Bool {
        for position in 0..<lhs.data.count {
            guard position < rhs.data.count else {
                return true
            }
            
            let byte = lhs.data[position]
            
            if byte < rhs.data[position] {
                return true
            }
            
            if byte > rhs.data[position] {
                return false
            }
        }
        
        return false
    }
    
    public static func >(lhs: IndexKey, rhs: IndexKey) -> Bool {
        for position in 0..<lhs.data.count {
            guard position < rhs.data.count else {
                return false
            }
            
            let byte = lhs.data[position]
            
            if byte > rhs.data[position] {
                return true
            }
            
            if byte < rhs.data[position] {
                return false
            }
        }
        
        return false
    }
}

class IndexTrieNode {
    var hashes = [Int]()
    var keyStorage = [IndexKey]()
    var nodeStorage = [IndexTrieNode]()
    var value: Int
    var fullyIndexed: Bool = false
    var recursivelyIndexed: Bool = false
    
    init(_ value: Int) {
        self.value = value
    }
    
    func checkFullyIndexed() {
        self.fullyIndexed = self.nodeStorage.reduce(true) { bool, item in
            return bool && item.fullyIndexed
        }
    }
    
    subscript(position path: [IndexKey]) -> Int? {
        get {
            guard path.count > 0 else {
                return nil
            }
            
            var position = 0
            var previousKeyLength = 0
            var node = self
            
            nextKey: for index in 0..<path.count {
                let currentKey = path[index]
                let currentHash = currentKey.hashValue
                
                keyScan: for hashIndex in 0..<node.hashes.count where node.hashes[hashIndex] == currentHash {
                    if node.keyStorage[hashIndex] == currentKey {
                        node = node.nodeStorage[hashIndex]
                        position += node.value &+ previousKeyLength
                        // + 6 for the sub document overhead (null terminators)
                        previousKeyLength = currentKey.data.count &+ 6
                        
                        continue nextKey
                    }
                }
                
                return nil
            }
            
            return position
        }
    }
    
    var count: Int {
        return nodeStorage.count
    }
    
    func copy() -> IndexTrieNode {
        let copy = IndexTrieNode(self.value)
        copy.recursivelyIndexed = self.recursivelyIndexed
        
        for node in self.nodeStorage {
            copy.nodeStorage.append(node.copy())
        }
        
        copy.keyStorage = self.keyStorage
        copy.hashes = self.hashes
        
        return copy
    }
    
    subscript(_ path: [IndexKey]) -> IndexTrieNode? {
        get {
            guard path.count > 0 else {
                return nil
            }
            
            var node = self
            
            nextKey: for index in 0..<path.count {
                let currentKey = path[index]
                let currentHash = currentKey.hashValue
                
                keyScan: for hashIndex in 0..<node.hashes.count where node.hashes[hashIndex] == currentHash {
                    if node.keyStorage[hashIndex] == currentKey {
                        node = node.nodeStorage[hashIndex]
                        
                        continue nextKey
                    }
                }
            }
            
            return node
        }
        set {
            guard path.count > 0 else {
                return
            }
            
            var node = self
            
            if let newValue = newValue {
                pathLoop: for index in 0..<path.count {
                    let currentKey = path[index]
                    let currentHash = currentKey.hashValue
                    var nodeIndex: Int? = nil
                    
                    keyScan: for hashIndex in 0..<node.hashes.count where node.hashes[hashIndex] == currentHash {
                        if node.keyStorage[hashIndex] == currentKey {
                            nodeIndex = hashIndex
                            break keyScan
                        }
                    }
                    
                    guard let additionIndex = nodeIndex else {
                        let newNode: IndexTrieNode
                        
                        if index == path.count - 1 {
                            newNode = newValue
                        } else {
                            newNode = IndexTrieNode(0)
                        }
                        
                        node.keyStorage.append(currentKey)
                        node.nodeStorage.append(newNode)
                        node.hashes.append(currentHash)
                        
                        node = newNode
                        continue pathLoop
                    }
                    
                    node = node.nodeStorage[additionIndex]
                }
            } else {
                for index in 0..<path.count {
                    let currentKey = path[index]
                    let currentHash = currentKey.hashValue
                    var nodeIndex: Int? = nil
                    
                    keyScan: for hashIndex in 0..<node.hashes.count where node.hashes[hashIndex] == currentHash {
                        if node.keyStorage[hashIndex] == currentKey {
                            nodeIndex = hashIndex
                            break keyScan
                        }
                    }
                    
                    guard let removalIndex = nodeIndex else {
                        return
                    }
                    
                    if index == path.count - 1 {
                        node.keyStorage.remove(at: removalIndex)
                        node.nodeStorage.remove(at: removalIndex)
                        node.hashes.remove(at: removalIndex)
                    }
                }
            }
        }
    }
}

