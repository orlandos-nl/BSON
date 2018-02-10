internal extension UInt8 {
    static let double: UInt8 = 0x01
    static let string: UInt8 = 0x02
    static let document: UInt8 = 0x03
    static let array: UInt8 = 0x04
    static let binary: UInt8 = 0x05
    static let objectId: UInt8 = 0x07
    static let boolean: UInt8 = 0x08
    static let datetime: UInt8 = 0x09
    static let null: UInt8 = 0x0a
    static let regex: UInt8 = 0x0b
//    static let dbPointer = 0x0c
    static let javascript: UInt8 = 0x0d
//    static let something = 0x0e
    static let javascriptWithScope: UInt8 = 0x0f
    static let int32: UInt8 = 0x10
    static let timestamp: UInt8 = 0x11
    static let int64: UInt8 = 0x12
    static let decimal128: UInt8 = 0x13
    static let minKey: UInt8 = 0xFF
    static let maxKey: UInt8 = 0x7F
}
