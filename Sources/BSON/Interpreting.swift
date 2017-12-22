//
//  Interpreting.swift
//  BSON
//
//  Created by Robbert Brandsma on 13-02-17.
//
//

import Foundation

extension Document: LossyPrimitive {
    public init?(lossy value: Primitive?) {
        if let value = value as? Document {
            self = value
            return
        }
        
        if let dict = value as? [String: Primitive] {
            self = Document(data: dict.makeBinary())
            return
        }
        
        if let array = value as? [Primitive] {
            self = Document(data: array.makeBinary())
            return
        }
        
        return nil
    }
}

extension Timestamp: LossyPrimitive {
    public init?(lossy value: Primitive?) {
        guard let value = value as? Timestamp else {
            return nil
        }
        
        self = value
    }
}

extension JavascriptCode: LossyPrimitive {
    public init?(lossy value: Primitive?) {
        guard let value = value as? JavascriptCode else {
            return nil
        }
        
        self = value
    }
}

extension Int: LossyPrimitive {
    public init?(lossy value: Primitive?) {
        switch value {
        case let val as Int32:
            self = Int(val)
        case let val as Int:
            self = val
        case let val as Double where val < Double(Int.max) && val > Double(Int.min):
            self = Int(val)
        case let val as String:
            if let parsed = Int(val) {
                self = parsed
            } else {
                return nil
            }
        default:
            return nil
        }
    }
}

extension Int32: LossyPrimitive {
    public init?(lossy value: Primitive?) {
        switch value {
        case let val as Int32:
            self = val
        case let val as Int:
            self = Int32(val)
        case let val as Double:
            self = Int32(val)
        case let val as String:
            if let parsed = Int32(val) {
                self = parsed
            } else {
                return nil
            }
        default:
            return nil
        }
    }
}

extension Double: LossyPrimitive {
    public init?(lossy value: Primitive?) {
        switch value {
        case let val as Double:
            self = val
        case let val as Int:
            self = Double(val)
        case let val as Int32:
            self = Double(val)
        case let val as String:
            if let parsed = Double(val) {
                self = parsed
            } else {
                return nil
            }
        default:
            return nil
        }
    }
}

extension String: LossyPrimitive {
    public init?(lossy value: Primitive?) {
        switch value {
        case let val as String:
            self = val
        case let val as Int:
            self = String(val)
        case let val as Int32:
            self = String(val)
        case let val as ObjectId:
            self = val.hexString
        case let val as Bool:
            self = val ? "true" : "false"
        default:
            return nil
        }
    }
}

extension Bool: LossyPrimitive {
    public init?(lossy value: Primitive?) {
        if let bool = value as? Bool {
            self = bool
        } else {
            self = Int(lossy: value) == 1
        }
    }
}

extension Binary: LossyPrimitive {
    public init?(lossy value: Primitive?) {
        guard let binary = value as? Binary else {
            return nil
        }
        
        self = binary
    }
}

extension Data: LossyPrimitive {
    public init?(lossy value: Primitive?) {
        guard let data = (value as? Binary)?.data else {
            return nil
        }
        
        self = data
    }
}

extension RegularExpression: LossyPrimitive {
    public init?(lossy value: Primitive?) {
        guard let regex = value as? RegularExpression else {
            return nil
        }
        
        self = regex
    }
}

extension ObjectId: LossyPrimitive {
    public init?(lossy value: Primitive?) {
        if let objectId = value as? ObjectId  {
            self = objectId
            return
        }
        
        guard let string = value as? String else {
            return nil
        }
        
        do {
            self = try ObjectId(string)
            return
        } catch {
            return nil
        }
    }
}

extension Date: LossyPrimitive {
    public init?(lossy value: Primitive?) {
        guard let date = value as? Date else {
            return nil
        }
        
        self = date
    }
}
