//
//  String.swift
//  BSON
//
//  Created by Robbert Brandsma on 18-04-16.
//
//

import Foundation

internal protocol BSONBytesProtocol {}

internal protocol BSONMakeBytesProtocol: BSONBytesProtocol {
    func makeBytes() -> Data
}

extension Int : BSONBytesProtocol {
    internal func makeBytes() -> Data {
        let integer = self.littleEndian
        
        return Data([
            numericCast(integer & 0xFF),
            numericCast((integer >> 8) & 0xFF),
            numericCast((integer >> 16) & 0xFF),
            numericCast((integer >> 24) & 0xFF),
            numericCast((integer >> 32) & 0xFF),
            numericCast((integer >> 40) & 0xFF),
            numericCast((integer >> 48) & 0xFF),
            numericCast((integer >> 56) & 0xFF),
        ])
    }
}

extension Int32 : BSONBytesProtocol {
    internal func makeBytes() -> Data {
        let integer = self.littleEndian
        
        return Data([
            numericCast(integer & 0xFF),
            numericCast((integer >> 8) & 0xFF),
            numericCast((integer >> 16) & 0xFF),
            numericCast((integer >> 24) & 0xFF),
        ])
    }
    
    internal func makeBigEndianBytes() -> Data {
        let integer = self.bigEndian
        
        return Data([
            numericCast(integer & 0xFF),
            numericCast((integer >> 8) & 0xFF),
            numericCast((integer >> 16) & 0xFF),
            numericCast((integer >> 24) & 0xFF),
        ])
    }
}

extension Int16 : BSONBytesProtocol {
    internal func makeBytes() -> Data {
        let integer = self.littleEndian
        
        return Data([
            numericCast((integer >> 8) & 0xFF),
            numericCast(integer & 0xFF)
        ])
    }
}

extension Int8 : BSONBytesProtocol {
    internal func makeBytes() -> Data {
        return Data([numericCast(self)])
    }
}

extension UInt : BSONBytesProtocol {
    internal func makeBytes() -> Data {
        let integer = self.littleEndian
        
        return Data([
            numericCast(integer & 0xFF),
            numericCast((integer >> 8) & 0xFF),
            numericCast((integer >> 16) & 0xFF),
            numericCast((integer >> 24) & 0xFF),
            numericCast((integer >> 32) & 0xFF),
            numericCast((integer >> 40) & 0xFF),
            numericCast((integer >> 48) & 0xFF),
            numericCast((integer >> 56) & 0xFF),
        ])
    }
}

extension UInt32 : BSONBytesProtocol {
    internal func makeBytes() -> Data {
        let integer = self.littleEndian
        
        return Data([
            numericCast(integer & 0xFF),
            numericCast((integer >> 8) & 0xFF),
            numericCast((integer >> 16) & 0xFF),
            numericCast((integer >> 24) & 0xFF),
        ])
    }
}

extension UInt16 : BSONBytesProtocol {
    internal func makeBytes() -> Data {
        let integer = self.littleEndian
        
        return Data([
            numericCast(integer & 0xFF),
            numericCast((integer >> 8) & 0xFF)
        ])
    }
}

extension UInt8 : BSONBytesProtocol {
    internal func makeBytes() -> Data {
        return Data([self])
    }
}

extension Double : BSONBytesProtocol {
    internal func makeBytes() -> Data {
        var integer = self
        return withUnsafePointer(to: &integer) { pointer in
            return pointer.withMemoryRebound(to: UInt8.self, capacity: MemoryLayout<Double>.size) {
                Data(UnsafeBufferPointer(start: $0, count: MemoryLayout<Double>.size))
            }
        }
    }
}

extension Data {
    internal subscript(offsetBy offset: Int) -> UInt8 {
        get {
            return self[self.startIndex.advanced(by: offset)]
        }
        set {
            self[self.startIndex.advanced(by: offset)] = newValue
        }
    }
}
