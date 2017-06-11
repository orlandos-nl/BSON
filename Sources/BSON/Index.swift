import KittenCore

struct IndexKey: Hashable {
    let keys: [KittenBytes]
    
    init(_ keys: [KittenBytes]) {
        self.keys = keys
    }
    
    init(_ parts: [SubscriptExpressionType]) {
        self.keys = parts.map {
            switch $0.subscriptExpression {
            case .kittenBytes(let bytes):
                return bytes
            case .integer(let pos):
                return pos.description.kittenBytes
            }
        }
    }
    
    var hashValue: Int {
        var hash = 0
        
        for (pos, key) in keys.enumerated() {
            hash = (hash &+ key.hashValue &+ pos) &* (pos &+ 1)
        }
        
        return hash
    }
    
    static func ==(lhs: IndexKey, rhs: IndexKey) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
    
    var s: String {
        return String(bytes: keys.map { $0.bytes }.joined(separator: []), encoding: .utf8)!
    }
}

class IndexTree {
    var storage = Dictionary<IndexKey, Int>()
    var fullyIndexed: Bool = false
    var unindexedList: [IndexKey : Int] = [IndexKey([]): 0]
    var complete: Bool {
        return fullyIndexed && unindexedList.count == 0
    }
    
    init() {}
}
