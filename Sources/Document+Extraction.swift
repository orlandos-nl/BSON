extension Document {
    public func extract<T: ValueConvertible>(_ key: String) -> T? {
        let response = self[key]
        
        guard response != .nothing else {
            return nil
        }
        
        if T.self == Int.self {
            return response.int as? T
        }
        
        return response.rawValue as? T
    }
}
