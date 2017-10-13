import Foundation

internal func fromBytes<T, S : Collection>(_ bytes: S) throws -> T where S.Iterator.Element == Byte, S.IndexDistance == Int {
    guard bytes.count >= MemoryLayout<T>.size else {
        throw DeserializationError.invalidElementSize
    }
    
    return Data(bytes).withUnsafeBytes { (pointer: UnsafePointer<T>) in
        return pointer.pointee
    }
}

extension Int32 {
    internal init(_ s: Data) {
        var val: Int32 = 0
        val |= s.count > 3 ? numericCast(s[offsetBy: 3]) << 24 : 0
        val |= s.count > 2 ? numericCast(s[offsetBy: 2]) << 16 : 0
        val |= s.count > 1 ? numericCast(s[offsetBy: 1]) << 8 : 0
        val |= s.count > 0 ? numericCast(s[s.startIndex]) : 0
        
        self = val
    }
}

extension Int {
    internal init(_ s: Data) {
        var number: Int = 0
        number |= s.count > 7 ? numericCast(s[offsetBy: 7]) << 56 : 0
        number |= s.count > 6 ? numericCast(s[offsetBy: 6]) << 48 : 0
        number |= s.count > 5 ? numericCast(s[offsetBy: 5]) << 40 : 0
        number |= s.count > 4 ? numericCast(s[offsetBy: 4]) << 32 : 0
        number |= s.count > 3 ? numericCast(s[offsetBy: 3]) << 24 : 0
        number |= s.count > 2 ? numericCast(s[offsetBy: 2]) << 16 : 0
        number |= s.count > 1 ? numericCast(s[offsetBy: 1]) << 8 : 0
        number |= s.count > 0 ? numericCast(s[offsetBy: 0]) << 0 : 0
        
        self = number
    }
}
