public final class BSONDecoder {
    public init() {}
    
    public func decode<D: Decodable>(_ d: D.Type, from value: Primitive) throws -> D {
        return try D(from: _BSONDecoder(input: value))
    }
}

struct BSONEncoderError: Error {}
struct BSONDecoderError: Error {}

fileprivate struct _BSONDecoder: Decoder {
    var codingPath: [CodingKey] = []
    var config = DecoderConfig()
    
    var userInfo: [CodingUserInfoKey : Any] = [:]
    
    var primitive: Primitive?
    var document: Document?
    
    var input: Primitive
    
    init(input: Primitive) {
        self.input = input
    }
    
    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
        return try KeyedDecodingContainer(BSONKeyedDecodingContainer<Key>(decoder: self))
    }
    
    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        return try BSONUnkeyedDecodingContainer(decoder: self)
    }
    
    func singleValueContainer() throws -> SingleValueDecodingContainer {
        return BSONPrimitiveDecodingContainer(decoder: self)
    }
}

extension Document {
    func next(index: inout Int) throws -> Primitive {
        guard let primitive = self[index] else {
            throw BSONDecoderError()
        }
        
        index += 1
        
        return primitive
    }
    
    func nextNull(index: inout Int) throws -> Bool {
        return try next(index: &index) is Null
    }
}

struct DecoderConfig {
    var lossy: Bool = false
    
    func extract<P: Primitive>(_ p: P.Type = P.self, for primitive: Primitive?) throws -> P {
        guard let primitive = primitive else {
            throw BSONDecoderError()
        }
        
        guard let p = P(primitive) else {
            throw BSONDecoderError()
        }
        
        return p
    }
    
    func lossyExtract<P: Primitive>(_ p: P.Type = P.self, for primitive: Primitive?) throws -> P {
        guard let primitive = primitive else {
            throw BSONDecoderError()
        }
        
        guard let p = p as? LossyPrimitive.Type else {
            throw BSONDecoderError()
        }
        
        guard let result = p.init(lossy: primitive) else {
            throw BSONDecoderError()
        }
        
        return result as! P
    }
    
    func lossyExtract<I: BinaryInteger>(_ p: I.Type = I.self, for primitive: Primitive?) throws -> I {
        //        if let int = Int(doc["doc"]) {
        //            if I.isSigned, int >= 0 {
        //                I
        //            }
        //        }
        fatalError()
    }
    
    func lossyExtract<FP: FloatingPoint>(_ p: FP.Type = FP.self, for primitive: Primitive?) throws -> FP {
        //        if let int = Int(doc["doc"]) {
        //            if I.isSigned, int >= 0 {
        //                I
        //            }
        //        }
        fatalError()
    }
    
    func extract<P: Primitive>(_ p: P.Type = P.self, index: inout Int, for doc: Document) throws -> P {
        guard let primitive = doc[index] else {
            throw BSONDecoderError()
        }
        
        guard let result = primitive as? P else {
            return try lossyExtract(for: primitive)
        }
        
        return result
    }
    
    func lossyExtract<I: BinaryInteger>(_ p: I.Type = I.self, index: inout Int, for doc: Document) throws -> I {
//        if let int = Int(doc["doc"]) {
//            if I.isSigned, int >= 0 {
//                I
//            }
//        }
        fatalError()
    }
    
    func lossyExtract<FP: FloatingPoint>(_ p: FP.Type = FP.self, index: inout Int, for doc: Document) throws -> FP {
        //        if let int = Int(doc["doc"]) {
        //            if I.isSigned, int >= 0 {
        //                I
        //            }
        //        }
        fatalError()
    }
}

fileprivate struct BSONUnkeyedDecodingContainer: UnkeyedDecodingContainer {
    var codingPath: [CodingKey] = []
    
    var count: Int? {
        return doc.count
    }
    
    var isAtEnd: Bool {
        return currentIndex >= count ?? 0
    }
    
    var currentIndex: Int = 0
    
    var doc: Document
    var config: DecoderConfig {
        return decoder.config
    }
    
    var decoder: _BSONDecoder
    
    init(decoder: _BSONDecoder) throws {
        guard let doc = decoder.primitive as? Document else {
            throw BSONDecoderError()
        }
        
        self.doc = doc
        self.decoder = decoder
    }
    
    mutating func decodeNil() throws -> Bool {
        return try doc.nextNull(index: &currentIndex)
    }
    
    mutating func decode(_ type: Bool.Type) throws -> Bool {
        return try config.extract(index: &currentIndex, for: doc)
    }
    
    mutating func decode(_ type: Int.Type) throws -> Int {
        return try config.extract(index: &currentIndex, for: doc)
    }
    
    mutating func decode(_ type: Int8.Type) throws -> Int8 {
        return try config.lossyExtract(index: &currentIndex, for: doc)
    }
    
    mutating func decode(_ type: Int16.Type) throws -> Int16 {
        return try config.lossyExtract(index: &currentIndex, for: doc)
    }
    
    mutating func decode(_ type: Int32.Type) throws -> Int32 {
        return try config.extract(index: &currentIndex, for: doc)
    }
    
    mutating func decode(_ type: Int64.Type) throws -> Int64 {
        return try config.lossyExtract(index: &currentIndex, for: doc)
    }
    
    mutating func decode(_ type: UInt.Type) throws -> UInt {
        return try config.lossyExtract(index: &currentIndex, for: doc)
    }
    
    mutating func decode(_ type: UInt8.Type) throws -> UInt8 {
        return try config.lossyExtract(index: &currentIndex, for: doc)
    }
    
    mutating func decode(_ type: UInt16.Type) throws -> UInt16 {
        return try config.lossyExtract(index: &currentIndex, for: doc)
    }
    
    mutating func decode(_ type: UInt32.Type) throws -> UInt32 {
        return try config.lossyExtract(index: &currentIndex, for: doc)
    }
    
    mutating func decode(_ type: UInt64.Type) throws -> UInt64 {
        return try config.lossyExtract(index: &currentIndex, for: doc)
    }
    
    mutating func decode(_ type: Float.Type) throws -> Float {
        return try config.lossyExtract(index: &currentIndex, for: doc)
    }
    
    mutating func decode(_ type: Double.Type) throws -> Double {
        return try config.extract(index: &currentIndex, for: doc)
    }
    
    mutating func decode(_ type: String.Type) throws -> String {
        return try config.extract(index: &currentIndex, for: doc)
    }
    
    mutating func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
        return try T(from: nextDecoder())
    }
    
    mutating func nextDecoder() throws -> _BSONDecoder {
        return try _BSONDecoder(input: doc.next(index: &currentIndex))
    }
    
    mutating func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
        return try nextDecoder().container(keyedBy: type)
    }
    
    mutating func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
        return try nextDecoder().unkeyedContainer()
    }
    
    mutating func superDecoder() throws -> Decoder {
        return decoder
    }
}

fileprivate struct BSONPrimitiveDecodingContainer: SingleValueDecodingContainer {
    var codingPath: [CodingKey] = []
    let decoder: _BSONDecoder
    var config: DecoderConfig {
        return decoder.config
    }
    
    init(decoder: _BSONDecoder) {
        self.decoder = decoder
    }
    
    func decodeNil() -> Bool {
        guard let primitive = decoder.primitive else {
            return true
        }
        
        return primitive is Null
    }
    
    func decode(_ type: Bool.Type) throws -> Bool {
        return try config.extract(for: decoder.input)
    }
    
    func decode(_ type: Int.Type) throws -> Int {
        return try config.extract(for: decoder.input)
    }
    
    func decode(_ type: Int8.Type) throws -> Int8 {
        return try config.lossyExtract(for: decoder.input)
    }
    
    func decode(_ type: Int16.Type) throws -> Int16 {
        return try config.lossyExtract(for: decoder.input)
    }
    
    func decode(_ type: Int32.Type) throws -> Int32 {
        return try config.extract(for: decoder.input)
    }
    
    func decode(_ type: Int64.Type) throws -> Int64 {
        return try config.lossyExtract(for: decoder.input)
    }
    
    func decode(_ type: UInt.Type) throws -> UInt {
        return try config.lossyExtract(for: decoder.input)
    }
    
    func decode(_ type: UInt8.Type) throws -> UInt8 {
        return try config.lossyExtract(for: decoder.input)
    }
    
    func decode(_ type: UInt16.Type) throws -> UInt16 {
        return try config.lossyExtract(for: decoder.input)
    }
    
    func decode(_ type: UInt32.Type) throws -> UInt32 {
        return try config.lossyExtract(for: decoder.input)
    }
    
    func decode(_ type: UInt64.Type) throws -> UInt64 {
        return try config.lossyExtract(for: decoder.input)
    }
    
    func decode(_ type: Float.Type) throws -> Float {
        return try config.lossyExtract(for: decoder.input)
    }
    
    func decode(_ type: Double.Type) throws -> Double {
        return try config.extract(for: decoder.input)
    }
    
    func decode(_ type: String.Type) throws -> String {
        return try config.extract(for: decoder.input)
    }
    
    func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
        return try T(from: decoder)
    }
}

fileprivate struct BSONKeyedDecodingContainer<K: CodingKey>: KeyedDecodingContainerProtocol {
    var codingPath: [CodingKey] = []
    var allKeys: [K] = []
    
    typealias Key = K
    
    var decoder: _BSONDecoder
    let doc: Document
    var config: DecoderConfig {
        return decoder.config
    }
    
    init(decoder: _BSONDecoder) throws {
        guard let doc = decoder.primitive as? Document else {
            throw BSONDecoderError()
        }
        
        self.doc = doc
        self.decoder = decoder
    }
    
    func contains(_ key: K) -> Bool {
        return doc.keys.contains(key.stringValue)
    }
    
    func decodeNil(forKey key: K) throws -> Bool {
        return try config.extract(for: doc[key.stringValue])
    }
    
    func decode(_ type: Bool.Type, forKey key: K) throws -> Bool {
        return try config.extract(for: doc[key.stringValue])
    }
    
    func decode(_ type: Int.Type, forKey key: K) throws -> Int {
        return try config.extract(for: doc[key.stringValue])
    }
    
    func decode(_ type: Int8.Type, forKey key: K) throws -> Int8 {
        return try config.lossyExtract(for: doc[key.stringValue])
    }
    
    func decode(_ type: Int16.Type, forKey key: K) throws -> Int16 {
        return try config.lossyExtract(for: doc[key.stringValue])
    }
    
    func decode(_ type: Int32.Type, forKey key: K) throws -> Int32 {
        return try config.extract(for: doc[key.stringValue])
    }
    
    func decode(_ type: Int64.Type, forKey key: K) throws -> Int64 {
        return try config.lossyExtract(for: doc[key.stringValue])
    }
    
    func decode(_ type: UInt.Type, forKey key: K) throws -> UInt {
        return try config.lossyExtract(for: doc[key.stringValue])
    }
    
    func decode(_ type: UInt8.Type, forKey key: K) throws -> UInt8 {
        return try config.lossyExtract(for: doc[key.stringValue])
    }
    
    func decode(_ type: UInt16.Type, forKey key: K) throws -> UInt16 {
        return try config.lossyExtract(for: doc[key.stringValue])
    }
    
    func decode(_ type: UInt32.Type, forKey key: K) throws -> UInt32 {
        return try config.lossyExtract(for: doc[key.stringValue])
    }
    
    func decode(_ type: UInt64.Type, forKey key: K) throws -> UInt64 {
        return try config.lossyExtract(for: doc[key.stringValue])
    }
    
    func decode(_ type: Float.Type, forKey key: K) throws -> Float {
        return try config.lossyExtract(for: doc[key.stringValue])
    }
    
    func decode(_ type: Double.Type, forKey key: K) throws -> Double {
        return try config.extract(for: doc[key.stringValue])
    }
    
    func decode(_ type: String.Type, forKey key: K) throws -> String {
        return try config.extract(for: doc[key.stringValue])
    }
    
    func decode<T>(_ type: T.Type, forKey key: K) throws -> T where T : Decodable {
        guard let primitive = doc[key.stringValue] else {
            throw BSONDecoderError()
        }
        
        return try T(from: _BSONDecoder(input: primitive))
    }
    
    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: K) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
        guard let primitive = doc[key.stringValue] else {
            throw BSONDecoderError()
        }
        
        return try _BSONDecoder(input: primitive).container(keyedBy: type)
    }
    
    func nestedUnkeyedContainer(forKey key: K) throws -> UnkeyedDecodingContainer {
        guard let primitive = doc[key.stringValue] else {
            throw BSONDecoderError()
        }
        
        return try _BSONDecoder(input: primitive).unkeyedContainer()
    }
    
    func superDecoder() throws -> Decoder {
        return decoder
    }
    
    func superDecoder(forKey key: K) throws -> Decoder {
        return decoder
    }
}
