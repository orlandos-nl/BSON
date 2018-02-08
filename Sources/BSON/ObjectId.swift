public struct ObjectId {
    let storage: Storage
    
    init(_ storage: Storage) {
        assert(storage.count == 12)
        
        self.storage = storage
    }
}
