extension Document: ExpressibleByArrayLiteral {
    /// Gets all top level values in this Document
    public var values: [Primitive] {
        var values = [Primitive]()
        values.reserveCapacity(32)

        var index = 4

        while index < storage.readableBytes {
            guard
                let typeNum = storage.getInteger(at: index, as: UInt8.self),
                let type = TypeIdentifier(rawValue: typeNum)
            else {
                return values
            }

            index += 1
            guard skipKey(at: &index) else {
                return values
            }

            guard let value = value(forType: type, at: index) else {
                return values
            }

            skipValue(ofType: type, at: &index)

            values.append(value)
        }

        return values
    }
    
    public subscript(index: Int) -> Primitive {
        get {
            var offset = 4
            for _ in 0..<index {
                guard skipKeyValuePair(at: &offset) else {
                    fatalError("Index \(index) out of range")
                }
            }

            guard
                let typeId = storage.getInteger(at: offset, as: UInt8.self),
                let type = TypeIdentifier(rawValue: typeId)
            else {
                fatalError("Index \(index) out of range")
            }

            guard skipKey(at: &offset), let value = self.value(forType: type, at: offset) else {
                fatalError("Index \(index) out of range")
            }

            return value
        }
        set {
            var offset = 4
            for _ in 0..<index {
                guard skipKeyValuePair(at: &offset) else {
                    fatalError("Index \(index) out of range")
                }
            }

            overwriteValue(with: newValue, atPairOffset: offset)
        }
    }

    public mutating func remove(at index: Int) {
        var offset = 4

        for _ in 0..<index {
            guard skipKeyValuePair(at: &offset) else {
                fatalError("Index \(index) out of range")
            }
        }

        let base = offset
        guard skipKeyValuePair(at: &offset) else {
            fatalError("Index \(index) out of range")
        }

        let length = offset - base

        self.removeBytes(at: base, length: length)
    }


    
    /// Appends a `Value` to this `Document` where this `Document` acts like an `Array`
    ///
    /// TODO: Analyze what should happen with `Dictionary`-like documents and this function
    ///
    /// - parameter value: The `Value` to append
    public mutating func append(_ value: Primitive) {
        let key = String(self.count)
        
        appendValue(value, forKey: key)
    }
    
    public init(arrayLiteral elements: PrimitiveConvertible...) {
        self.init(array: elements.compactMap { $0.makePrimitive() } )
    }
    
    /// Converts an array of Primitives to a BSON ArrayDocument
    public init(array: [Primitive]) {
        self.init(isArray: true)
        
        for element in array {
            self.append(element)
        }
    }
}

extension Array where Element == Primitive {
    public init(valuesOf document: Document) {
        self = document.values
    }
}
