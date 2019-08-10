public struct JavaScriptCode: Primitive, ExpressibleByStringLiteral, Hashable {
    public var code: String
    
    public init(_ code: String) {
        self.code = code
    }
    
    public init(stringLiteral value: String) {
        self.code = value
    }
}

public struct JavaScriptCodeWithScope: Primitive, Hashable {
    public var code: String
    public var scope: Document
    
    public init(_ code: String, scope: Document) {
        self.code = code
        self.scope = scope
    }
}
