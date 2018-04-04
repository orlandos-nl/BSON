import Foundation

extension Document {
    func serializeData() -> Data {
        return Data(buffer: self.storage.readBuffer) + [0]
    }
}
