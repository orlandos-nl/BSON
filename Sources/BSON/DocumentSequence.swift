import Foundation

extension Array where Element == Document {
    /// The combined data for all documents in the array
    public var bytes: Data {
        var fullBuffer = Data()
        
        let size = self.reduce(0, { size, doc in
            return size + doc.byteCount
        })
        
        fullBuffer.reserveCapacity(size)
        
        for doc in self {
            fullBuffer.append(contentsOf: doc.bytes)
        }
        
        return fullBuffer
    }
    
    public init(bsonBytes bytes: Data, validating: Bool = false) {
        var array = [Element]()
        var position = 0
        let byteCount = bytes.count
        
        documentLoop: while byteCount >= position + 5 {
            let length = bytes.withUnsafeBytes { (pointer: UnsafePointer<UInt8>) in
                return pointer.advanced(by: position).withMemoryRebound(to: Int32.self, capacity: 1) { pointer in
                    return numericCast(pointer.pointee)
                }
            } as Int
            
            guard length > 0 else {
                // invalid
                break
            }
            
            guard byteCount >= position + length else {
                break documentLoop
            }
            
            let document = Element(data: Data(bytes[position..<position+length]))
            
            if validating {
                if document.validate() {
                    array.append(document)
                }
            } else {
                array.append(document)
            }
            
            position += length
        }
        
        self = array
    }
}

extension Sequence where Iterator.Element == Document {
    /// Converts a sequence of Documents to an array of documents in BSON format
    public func makeDocument() -> Document {
        var combination = [] as Document
        for doc in self {
            combination.append(doc)
        }
        
        return combination
    }
}

extension Array where Element == Primitive {
    public init?(_ value: Primitive?) {
        guard let document = value as? Document else {
            return nil
        }
        
        self = document.arrayRepresentation
    }
}

extension Dictionary where Key == String, Value == Primitive {
    public init?(_ value: Primitive?) {
        guard let document = value as? Document else {
            return nil
        }
        
        self = document.dictionaryRepresentation
    }
}
