extension UnsafePointer {
    var int32: Int32 {
        return self.withMemoryRebound(to: Int32.self, capacity: 1) { $0.pointee }
    }
    
    var int64: Int64 {
        return self.withMemoryRebound(to: Int64.self, capacity: 1) { $0.pointee }
    }
}
