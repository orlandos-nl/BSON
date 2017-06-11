import KittenCore

struct IndexKey: Hashable {
    let keys: [KittenBytes]
    let hashValue: Int
    
    init(_ keys: [KittenBytes]) {
        self.keys = keys
        
        guard keys.count > 0 else {
            self.hashValue = 0
            return
        }
        
        var hash = 0
        var h2: Int
        
        for i in 0..<keys.count {
            guard keys[i].bytes.count > 0 else {
                hash = (hash &+ i) &* (i &+ 1)
                continue
            }
            
            h2 = 0
            
            for j in 0..<keys[i].bytes.count {
                h2 = 31 &* h2 &+ numericCast(keys[i].bytes[j])
            }
            
            hash = (hash &+ h2 &+ i) &* (i &+ 1)
        }
        
        self.hashValue = hash
    }
    
    init(_ parts: [SubscriptExpressionType]) {
        self.init(parts.map {
            switch $0.subscriptExpression {
            case .kittenBytes(let bytes):
                return bytes
            case .integer(let pos):
                return pos.description.kittenBytes
            }
        })
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
    //var unindexedList: [IndexKey : Int] = [IndexKey([]): 0]
    var complete: Bool {
        return fullyIndexed// && unindexedList.count == 0
    }
    
    init() {}
}
