extension Document {
    /// Extracts any `Primitive` fom the value at key `key`
    public subscript(key: String) -> Primitive? {
        get {
            var offset = 4

            repeat {
                guard
                    let typeId = storage.getInteger(at: offset, as: UInt8.self),
                    let type = TypeIdentifier(rawValue: typeId)
                else {
                    return nil
                }

                offset += 1

                let matches = matchesKey(key, at: offset)
                guard skipKey(at: &offset) else {
                    return nil
                }

                if matches {
                    return value(forType: type, at: offset)
                }

                guard skipValue(ofType: type, at: &offset) else {
                    return nil
                }
            } while offset + 1 < storage.readableBytes

            return nil
        }
        set {
            var offset = 4

            findKey: repeat {
                let baseOffset = offset

                guard
                    let typeId = storage.getInteger(at: offset, as: UInt8.self)
                else {
                    return
                }

                guard
                    let type = TypeIdentifier(rawValue: typeId)
                else {
                    if typeId == 0x00 {
                        break findKey
                    }

                    return
                }

                offset += 1

                let matches = matchesKey(key, at: offset)

                guard skipKey(at: &offset) else {
                    return
                }

                if matches, let valueLength = self.valueLength(forType: type, at: offset) {
                    let end = offset + valueLength
                    let length = end - baseOffset
                    self.removeBytes(at: baseOffset, length: length)
                    break findKey
                }

                guard skipValue(ofType: type, at: &offset) else {
                    return
                }
            } while offset + 1 < storage.readableBytes

            if let newValue = newValue {
                appendValue(newValue, forKey: key)
            }
        }
    }
}
