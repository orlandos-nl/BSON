extension Document: ExpressibleByArrayLiteral {
    /// Gets all top level values in this Document
    public var values: [Primitive] {
        ensureFullyCached()
        
        return cache.cachedDimensions.compactMap(self.readPrimitive)
    }
    
    public subscript(index: Int) -> Primitive {
        get {
            repeat {
                if cache.count > index {
                    return self[valueFor: cache[index].dimensions]
                }
                
                _ = self.scanValue(startingAt: cache.lastScannedPosition, mode: .single)
            } while !self.fullyCached
            
            fatalError("Index \(index) out of range")
        }
        set {
            repeat {
                if cache.count > index {
                    self.write(newValue, forDimensions: cache[index].dimensions, key: "\(index)")
                }
                
                _ = self.scanValue(startingAt: cache.lastScannedPosition, mode: .single)
            } while !self.fullyCached
            
            // TODO: Investigate other options than fatalError()
            fatalError("Index \(index) out of range")
        }
    }
    
    /// Appends a `Value` to this `Document` where this `Document` acts like an `Array`
    ///
    /// TODO: Analyze what should happen with `Dictionary`-like documents and this function
    ///
    /// - parameter value: The `Value` to append
    public mutating func append(_ value: Primitive) {
        let key = String(self.count)
        
        self.write(value, forKey: key)
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
