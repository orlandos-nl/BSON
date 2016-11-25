extension Document {
    public func extract<V: CustomValueConvertible>(_ key: SubscriptExpressionType...) -> V? {
        guard let primitive = self[key]?.makeBSONPrimitive() else {
            return nil
        }
        
        return V(primitive)
    }
}
