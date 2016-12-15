import Foundation

extension Document {
    public subscript(parts: SubscriptExpressionType...) -> String? {
        get {
            return self[raw: parts]?.string
        }
        set {
            self[raw: parts] = newValue
        }
    }
    
    public subscript(parts: SubscriptExpressionType...) -> Int? {
        get {
            return self[raw: parts]?.int
        }
        set {
            self[raw: parts] = newValue
        }
    }
    
    public subscript(parts: SubscriptExpressionType...) -> Int32? {
        get {
            return self[raw: parts]?.int32
        }
        set {
            self[raw: parts] = newValue
        }
    }
    
    public subscript(parts: SubscriptExpressionType...) -> Int64? {
        get {
            return self[raw: parts]?.int64
        }
        set {
            self[raw: parts] = newValue
        }
    }
    
    public subscript(parts: SubscriptExpressionType...) -> Bool? {
        get {
            return self[raw: parts]?.boolValue
        }
        set {
            self[raw: parts] = newValue
        }
    }
    
    public subscript(parts: SubscriptExpressionType...) -> Double? {
        get {
            return self[raw: parts]?.double
        }
        set {
            self[raw: parts] = newValue
        }
    }
    
    public subscript(parts: SubscriptExpressionType...) -> Date? {
        get {
            return self[raw: parts]?.dateValue
        }
        set {
            self[raw: parts] = newValue
        }
    }
    
    public subscript(parts: SubscriptExpressionType...) -> Document? {
        get {
            return self[raw: parts]?.documentValue
        }
        set {
            self[raw: parts] = newValue
        }
    }
    
    public subscript(parts: SubscriptExpressionType...) -> [String: ValueConvertible]? {
        get {
            return (self[parts] as Document?)?.dictionaryValue
        }
        set {
            if let newValue = newValue {
                self[raw: parts] = Document(dictionaryElements: newValue.map { ($0.0, $0.1) })
            } else {
                self[raw: parts] = nil
            }
        }
    }
    
    public subscript(parts: SubscriptExpressionType...) -> [ValueConvertible]? {
        get {
            return (self[parts] as Document?)?.arrayValue
        }
        set {
            if let newValue = newValue {
                self[raw: parts] = Document(array: newValue)
            } else {
                self[raw: parts] = nil
            }
        }
    }
    
    public subscript(parts: SubscriptExpressionType...) -> ObjectId? {
        get {
            return self[raw: parts]?.objectIdValue
        }
        set {
            self[raw: parts] = newValue
        }
    }
    
    public subscript(parts: SubscriptExpressionType...) -> Timestamp? {
        get {
            return self[raw: parts] as? Timestamp
        }
        set {
            self[raw: parts] = newValue
        }
    }
    
    public subscript(parts: SubscriptExpressionType...) -> Binary? {
        get {
            return self[raw: parts] as? Binary
        }
        set {
            self[raw: parts] = newValue
        }
    }
    
    public subscript(parts: SubscriptExpressionType...) -> Data? {
        get {
            return (self[raw: parts] as? Binary)?.data
        }
        set {
            self[raw: parts] = newValue
        }
    }
    
    public subscript(parts: SubscriptExpressionType...) -> Null? {
        get {
            return self[raw: parts] as? Null
        }
        set {
            self[raw: parts] = newValue
        }
    }
    
    public subscript(parts: SubscriptExpressionType...) -> JavascriptCode? {
        get {
            return self[raw: parts] as? JavascriptCode
        }
        set {
            self[raw: parts] = newValue
        }
    }
    
    public subscript(parts: SubscriptExpressionType...) -> RegularExpression? {
        get {
            return self[raw: parts] as? RegularExpression
        }
        set {
            self[raw: parts] = newValue
        }
    }
}

extension Document {
    public subscript(parts: [SubscriptExpressionType]) -> String? {
        get {
            return self[raw: parts]?.string
        }
        set {
            self[raw: parts] = newValue
        }
    }
    
    public subscript(parts: [SubscriptExpressionType]) -> Int? {
        get {
            return self[raw: parts]?.int
        }
        set {
            self[raw: parts] = newValue
        }
    }
    
    public subscript(parts: [SubscriptExpressionType]) -> Int32? {
        get {
            return self[raw: parts]?.int32
        }
        set {
            self[raw: parts] = newValue
        }
    }
    
    public subscript(parts: [SubscriptExpressionType]) -> Int64? {
        get {
            return self[raw: parts]?.int64
        }
        set {
            self[raw: parts] = newValue
        }
    }
    
    public subscript(parts: [SubscriptExpressionType]) -> Bool? {
        get {
            return self[raw: parts]?.boolValue
        }
        set {
            self[raw: parts] = newValue
        }
    }
    
    public subscript(parts: [SubscriptExpressionType]) -> Double? {
        get {
            return self[raw: parts]?.double
        }
        set {
            self[raw: parts] = newValue
        }
    }
    
    public subscript(parts: [SubscriptExpressionType]) -> Date? {
        get {
            return self[raw: parts]?.dateValue
        }
        set {
            self[raw: parts] = newValue
        }
    }
    
    public subscript(parts: [SubscriptExpressionType]) -> Document? {
        get {
            return self[raw: parts]?.documentValue
        }
        set {
            self[raw: parts] = newValue
        }
    }
    
    public subscript(parts: [SubscriptExpressionType]) -> ObjectId? {
        get {
            return self[raw: parts]?.objectIdValue
        }
        set {
            self[raw: parts] = newValue
        }
    }
    
    public subscript(parts: [SubscriptExpressionType]) -> Timestamp? {
        get {
            return self[raw: parts] as? Timestamp
        }
        set {
            self[raw: parts] = newValue
        }
    }
    
    public subscript(parts: [SubscriptExpressionType]) -> Binary? {
        get {
            return self[raw: parts] as? Binary
        }
        set {
            self[raw: parts] = newValue
        }
    }
    
    public subscript(parts: [SubscriptExpressionType]) -> Data? {
        get {
            return (self[raw: parts] as? Binary)?.data
        }
        set {
            self[raw: parts] = newValue
        }
    }
    
    public subscript(parts: [SubscriptExpressionType]) -> Null? {
        get {
            return self[raw: parts] as? Null
        }
        set {
            self[raw: parts] = newValue
        }
    }
    
    public subscript(parts: [SubscriptExpressionType]) -> JavascriptCode? {
        get {
            return self[raw: parts] as? JavascriptCode
        }
        set {
            self[raw: parts] = newValue
        }
    }
    
    public subscript(parts: [SubscriptExpressionType]) -> RegularExpression? {
        get {
            return self[raw: parts] as? RegularExpression
        }
        set {
            self[raw: parts] = newValue
        }
    }
}
