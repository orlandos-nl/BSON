import Foundation

public struct Decimal128: Primitive {
    public var typeIdentifier: UInt8 {
        return 0x13
    }
    
    fileprivate var _storage = Data()
    
    internal init?(slice: Data) {
        self._storage = Data(slice)
        
        guard self._storage.count == 16 else {
            return nil
        }
    }
    
    public func makeBinary() -> Data {
        return self._storage
    }
}
