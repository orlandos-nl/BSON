/// - **Warning:** This enum is not exhaustive and may grow in the future. Always combine this with a `default` case in switch statements.
public enum TypeIdentifier: UInt8 {
    case double = 0x01
    case string = 0x02
    case document = 0x03
    case array = 0x04
    case binary = 0x05

    // Deprecated case undefined = 0x06

    case objectId = 0x07
    case boolean = 0x08
    case datetime = 0x09
    case null = 0x0a
    case regex = 0x0b

    // Deprecated: case dbPointer = 0x0c

    case javascript = 0x0d

    // Deprecated case symbol = 0x0e

    /// Deprecated
    case javascriptWithScope = 0x0f

    case int32 = 0x10
    case timestamp = 0x11
    case int64 = 0x12
    case decimal128 = 0x13
    case minKey = 0xFF
    case maxKey = 0x7F
}
