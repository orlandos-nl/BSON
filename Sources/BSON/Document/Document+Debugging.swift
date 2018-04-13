extension Document : CustomDebugStringConvertible {
    public var debugDescription: String {
        return "[" +
            self.map { "\"\($0.key)\": \(String(reflecting: $0.value))" }
            .joined(separator: ", ")
            + "]"
    }
}
