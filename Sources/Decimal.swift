import Foundation

public struct Decimal128: BSONPrimitive {
    public var typeIdentifier: UInt8 {
        return 0x13
    }
    
    public typealias Raw = (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8)
    
    fileprivate var _storage = [UInt8]()
    
    public var raw: Raw {
        get {
            return (_storage[0], _storage[1], _storage[2], _storage[3], _storage[4], _storage[5], _storage[6], _storage[7], _storage[8], _storage[9], _storage[10], _storage[11], _storage[12], _storage[13], _storage[14], _storage[15])
        }
        set {
            self._storage = [
                newValue.0, newValue.1, newValue.2, newValue.3, newValue.4, newValue.5, newValue.6, newValue.7, newValue.8, newValue.9, newValue.10, newValue.11, newValue.12, newValue.13, newValue.14, newValue.15
            ]
        }
    }
    
    internal init?(slice: ArraySlice<UInt8>) {
        self._storage = Array(slice)
        
        guard self._storage.count == 16 else {
            return nil
        }
    }
    
    public init(raw: Raw) {
        self.raw = raw
    }
    
    public func makeBSONBinary() -> [UInt8] {
        return self._storage
    }
}
