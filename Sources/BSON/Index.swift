struct IndexKey: Hashable {
    let key: KittenBytes
    let hashValue: Int
    
    init(_ key: KittenBytes) {
        self.key = key
        self.hashValue = key.hashValue
    }
    
    static func ==(lhs: IndexKey, rhs: IndexKey) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
    
    var s: String {
        return String(bytes: key.bytes, encoding: .utf8)!
    }
}

class IndexTrieNode {
    fileprivate var keyStorage = [IndexKey]()
    fileprivate var nodeStorage = [IndexTrieNode]()
    var value: Int
    var fullyIndexed: Bool = false
    
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
            var pathIndex = 0
            var key: IndexKey
            var nodeIndex: Int
            var node: IndexTrieNode
            var previousKeyLength = 0
            
            repeat {
                key = path[pathIndex]
                
                guard let index = path.index(of: key) else {
                    return nil
                }
                
                nodeIndex = index
                node = node.nodeStorage[nodeIndex]
                
                position += node.value &+ 6 &+ previousKeyLength
                previousKeyLength = key.key.bytes.count
                
                pathIndex = pathIndex &+ 1
            } while pathIndex < path.count
            
            guard pathIndex == path.count else {
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
        copy.fullyIndexed = self.fullyIndexed
        
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
            
            var pathIndex = 0
            var key: IndexKey
            var nodeIndex: Int
            var node: IndexTrieNode
            
            repeat {
                key = path[pathIndex]
                
                guard let index = path.index(of: key) else {
                    return nil
                }
                
                nodeIndex = index
                node = node.nodeStorage[nodeIndex]
                
                pathIndex = pathIndex &+ 1
            } while pathIndex < path.count
            
            guard pathIndex == path.count else {
                return nil
            }
            
            return node
        }
        set {
            guard path.count > 0 else {
                return
            }
            
            var pathIndex = 0
            var key: IndexKey
            var nodeIndex: Int
            var node = self
            
            func applyToNode(key: IndexKey) {
                guard let index = node.keyStorage.index(of: key) else {
                    guard let newValue = newValue else {
                        return
                    }
                    
                    var key = key
                    
                    repeat {
                        node.keyStorage.append(key)
                        
                        let newNode = IndexTrieNode(0)
                        node.nodeStorage.append(newNode)
                        
                        node = newNode
                        
                        pathIndex = pathIndex &+ 1
                        
                        if pathIndex < path.count {
                            key = path[pathIndex]
                        }
                    } while pathIndex + 1 < path.count
                    
                    node.nodeStorage.append(newValue)
                        
                    return
                }
                
                if let newValue = newValue {
                    if isKnownUniquelyReferenced(&node) {
                        node.nodeStorage[index] = newValue
                    } else {
                        let copy = node.copy()
                        
                        copy.nodeStorage[index] = newValue
                        
                        node = copy
                    }
                } else {
                    if isKnownUniquelyReferenced(&node) {
                        node.nodeStorage.remove(at: index)
                    } else {
                        let copy = node.copy()
                        
                        copy.keyStorage.remove(at: index)
                        copy.nodeStorage.remove(at: index)
                        
                        node = copy
                    }
                }
            }
            
            guard path.count > 1, let index = node.keyStorage.index(of: path[0]) else {
                applyToNode(key: path[0])
                return
            }
            
            pathIndex = pathIndex &+ 1
            nodeIndex = index
            node = node.nodeStorage[nodeIndex]
            
            while pathIndex < path.count {
                key = path[pathIndex]
                
                if let index = path.index(of: key) {
                    nodeIndex = index
                    node = node.nodeStorage[nodeIndex]
                } else {
                    applyToNode(key: key)
                    return
                }
                
                pathIndex = pathIndex &+ 1
                
                if pathIndex == path.count {
                    applyToNode(key: key)
                }
            }
        }
    }
}

