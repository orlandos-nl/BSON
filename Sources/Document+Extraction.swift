extension _Document {
    public func extract<T: ValueConvertible>(_ key: String) -> T? {
        let response = self[key]
        
        guard response != .nothing else {
            return nil
        }
        
        return response.rawValue as? T
    }
}
