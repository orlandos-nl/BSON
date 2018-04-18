extension Document : Equatable {
    public static func == (lhs: Document, rhs: Document) -> Bool {
        // TODO: Fix this when makeData() is'nt mutating
        var a = lhs
        var b = rhs
        return a.makeData() == b.makeData()
    }
}
