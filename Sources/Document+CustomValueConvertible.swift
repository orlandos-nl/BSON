extension Document {
    public func extract<V: CustomValueConvertible>(_ key: String) -> V? {
        return V(self[key]?.makeBsonValue() ?? .nothing)
    }
    
    public func extract<V: CustomValueConvertible>(literal key: String) -> V? {
        return V(self[literal: key]?.makeBsonValue() ?? .nothing)
    }
    
    public func extract<V: CustomValueConvertible>(_ firstKey: String, _ otherKeys: String...) -> V? {
        return V(self[[firstKey] + otherKeys]?.makeBsonValue() ?? .nothing)
    }
}
