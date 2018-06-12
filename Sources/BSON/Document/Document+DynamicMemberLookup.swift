import Foundation

// TODO: Discuss if Dynamic Member Lookup should try to convert values
// TODO: Add missing primitives

extension Document {
    
    public subscript(dynamicMember member: String) -> String? {
        get {
            return self[member] as? String
        }
        set {
            self[member] = newValue
        }
    }
    
    public subscript(dynamicMember member: String) -> Int? {
        get {
            return self[member] as? Int
        }
        set {
            self[member] = newValue
        }
    }
    
    public subscript(dynamicMember member: String) -> Int32? {
        get {
            return self[member] as? Int32
        }
        set {
            self[member] = newValue
        }
    }
    
    public subscript(dynamicMember member: String) -> ObjectId? {
        get {
            return self[member] as? ObjectId
        }
        set {
            self[member] = newValue
        }
    }
    
    public subscript(dynamicMember member: String) -> Document? {
        get {
            return self[member] as? Document
        }
        set {
            self[member] = newValue
        }
    }
    
    public subscript(dynamicMember member: String) -> Date? {
        get {
            return self[member] as? Date
        }
        set {
            self[member] = newValue
        }
    }
    
}
