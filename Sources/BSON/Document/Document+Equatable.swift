extension Document: Equatable {
    public static func == (lhs: Document, rhs: Document) -> Bool {
        return lhs.makeData() == rhs.makeData()
    }
}

extension Document: Hashable {
    public func hash(into hasher: inout Hasher) {
        self.makeByteBuffer().withUnsafeReadableBytes { buffer in
            hasher.combine(bytes: buffer)
        }
    }
}
