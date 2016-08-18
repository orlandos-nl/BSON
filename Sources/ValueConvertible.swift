//
//  ValueConvertible.swift
//  BSON
//
//  Created by Robbert Brandsma on 18-04-16.
//
//

import Foundation

public protocol ValueConvertible {
    /// Converts this instance to a BSON `Value`
    func makeBsonValue() -> Value
}

extension Bool : ValueConvertible {
    /// Converts this instance to a BSON `Value`
    public func makeBsonValue() -> Value {
        return .boolean(self)
    }
}

extension Double : ValueConvertible {
    /// Converts this instance to a BSON `Value`
    public func makeBsonValue() -> Value {
        return .double(self)
    }
}

extension Int32 : ValueConvertible {
    /// Converts this instance to a BSON `Value`
    public func makeBsonValue() -> Value {
        return .int32(self)
    }
}

extension Int64 : ValueConvertible {
    /// Converts this instance to a BSON `Value`
    public func makeBsonValue() -> Value {
        return .int64(self)
    }
}

extension Int : ValueConvertible {
    /// Converts this instance to a BSON `Value`
    public func makeBsonValue() -> Value {
        return .int64(Int64(self))
    }
}

extension Date : ValueConvertible {
    /// Converts this instance to a BSON `Value`
    public func makeBsonValue() -> Value {
        return .dateTime(self)
    }
}

extension String : ValueConvertible {
    /// Converts this instance to a BSON `Value`
    public func makeBsonValue() -> Value {
        return .string(self)
    }
}

extension Document : ValueConvertible {
    /// Converts this instance to a BSON `Value`
    public func makeBsonValue() -> Value {
        return self.validatesAsArray() ? .array(self) : .document(self)
    }
}

extension ObjectId : ValueConvertible {
    /// Converts this instance to a BSON `Value`
    public func makeBsonValue() -> Value {
        return .objectId(self)
    }
}

extension Value : ValueConvertible {
    /// Converts this instance to a BSON `Value`
    public func makeBsonValue() -> Value {
        return self
    }
}

prefix operator ~ {}
public prefix func ~(convertible: ValueConvertible) -> Value {
    return convertible.makeBsonValue()
}
