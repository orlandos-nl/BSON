extension Document : CustomDebugStringConvertible {
    public var debugDescription: String {
        return "[" +
            self.map { isArray ? String(reflecting: $0.value) : "\"\($0.key)\": \(String(reflecting: $0.value))" }
            .joined(separator: ", ")
            + "]"
    }
}

extension ObjectId : CustomDebugStringConvertible {
    public var debugDescription: String {
        return "ObjectId(\"\(self.hexString)\")"
    }
}
