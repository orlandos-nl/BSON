//
//  ValueConvertible.swift
//  BSON
//
//  Created by Robbert Brandsma on 18-04-16.
//
//

import Foundation

public protocol ValueConvertible {
    func makeBsonValue() -> Value
}

extension Bool : ValueConvertible {
    public func makeBsonValue() -> Value {
        return .boolean(self)
    }
}

extension Double : ValueConvertible {
    public func makeBsonValue() -> Value {
        return .double(self)
    }
}

extension Int32 : ValueConvertible {
    public func makeBsonValue() -> Value {
        return .int32(self)
    }
}

extension Int64 : ValueConvertible {
    public func makeBsonValue() -> Value {
        return .int64(self)
    }
}

extension Int : ValueConvertible {
    public func makeBsonValue() -> Value {
        return .int64(Int64(self))
    }
}

extension NSDate : ValueConvertible {
    public func makeBsonValue() -> Value {
        return .dateTime(self)
    }
}

extension String : ValueConvertible {
    public func makeBsonValue() -> Value {
        return .string(self)
    }
}

extension Document : ValueConvertible {
    public func makeBsonValue() -> Value {
        return self.validatesAsArray() ? .array(self) : .document(self)
    }
}

extension ObjectId : ValueConvertible {
    public func makeBsonValue() -> Value {
        return .objectId(self)
    }
}

extension Value : ValueConvertible {
    public func makeBsonValue() -> Value {
        return self
    }
}

prefix operator ~ {}
public prefix func ~(convertible: ValueConvertible) -> Value {
    return convertible.makeBsonValue()
}