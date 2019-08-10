/// Special internal type used by MongoDB replication and sharding. First 4 bytes are an increment, second 4 are a timestamp.
public struct Timestamp: Primitive, Hashable {    
    public var increment: Int32
    public var timestamp: Int32
    
    public static func ==(lhs: Timestamp, rhs: Timestamp) -> Bool {
        return lhs.increment == rhs.increment && lhs.timestamp == rhs.timestamp
    }
    
    public init(increment: Int32, timestamp: Int32) {
        self.increment = increment
        self.timestamp = timestamp
    }
}
