extension Document: Equatable {
    public static func == (lhs: Document, rhs: Document) -> Bool {
        return lhs.makeData() == rhs.makeData()
    }
}
