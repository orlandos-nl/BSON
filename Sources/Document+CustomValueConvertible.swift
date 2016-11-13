extension Document {
    public func extract<V: CustomValueConvertible>(_ key: String...) -> V? {
        return V(self[key]?.makeBsonValue() ?? .nothing)
    }
}
