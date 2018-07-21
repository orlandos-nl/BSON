extension Document: Equatable {
    public static func == (lhs: Document, rhs: Document) -> Bool {
        // TODO: Fix this when makeData() is'nt mutating
        let a = lhs
        let b = rhs
        return a.makeData() == b.makeData()
    }
}
