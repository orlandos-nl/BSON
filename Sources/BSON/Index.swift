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
        return lhs.data == rhs.data
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
            
            for index in 0..<path.count {
                let currentKey = path[index]
                
                guard let nodeIndex = node.keyStorage.index(of: currentKey) else {
                    return nil
                }
                
                node = node.nodeStorage[nodeIndex]
                position += node.value &+ previousKeyLength
                // + 6 for the sub document overhead (null terminators)
                previousKeyLength = currentKey.data.count &+ 6
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
        
        return copy
    }
    
    subscript(_ path: [IndexKey]) -> IndexTrieNode? {
        get {
            guard path.count > 0 else {
                return nil
            }
            
            var node = self
            
            for index in 0..<path.count {
                let currentKey = path[index]
                
                guard let nodeIndex = node.keyStorage.index(of: currentKey) else {
                    return nil
                }
                
                node = node.nodeStorage[nodeIndex]
            }
            
            return node
        }
        set {
            guard path.count > 0 else {
                return
            }
            
            var node = self
            
            if let newValue = newValue {
                for index in 0..<path.count {
                    let currentKey = path[index]
                    
                    if let nodeIndex = node.keyStorage.index(of: currentKey) {
                        node = node.nodeStorage[nodeIndex]
                    } else {
                        let newNode: IndexTrieNode
                        
                        if index == path.count - 1 {
                            newNode = newValue
                        } else {
                            newNode = IndexTrieNode(0)
                        }
                        
                        node.keyStorage.append(currentKey)
                        node.nodeStorage.append(newNode)
                        
                        node = newNode
                    }
                }
            } else {
                for index in 0..<path.count {
                    let currentKey = path[index]
        
                    guard let nodeIndex = node.keyStorage.index(of: currentKey) else {
                        return
                    }
                    
                    if index == path.count - 1 {
                        node.keyStorage.remove(at: nodeIndex)
                        node.nodeStorage.remove(at: nodeIndex)
                    }
                }
            }
        }
    }
}

