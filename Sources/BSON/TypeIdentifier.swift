internal extension UInt8 {
    static let double = 0x01
    static let string = 0x02
    static let document = 0x03
    static let array = 0x04
    static let binary = 0x05
    static let objectId = 0x07
    static let boolean = 0x08
    static let datetime = 0x09
    static let regex = 0x0a
    static let dbPointer = 0x0b
//    static let dbPointer = 0x0c
    static let javascript = 0x0d
//    static let double = 0x0e
    static let javascriptWithScope = 0x0f
    static let int32 = 0x10
    static let timestamp = 0x11
    static let int64 = 0x12
    static let decimal128 = 0x13
    static let minKey = 0xFF
    static let maxKey = 0x7F
}
