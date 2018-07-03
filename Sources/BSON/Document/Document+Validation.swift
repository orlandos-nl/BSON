public struct ValidationResult {
    public let valid: Bool
    public internal(set) var errorPosition: Int?
    public let reason: StaticString?
    
    static func valid() -> ValidationResult {
        return ValidationResult(valid: true, errorPosition: nil, reason: nil)
    }
}

fileprivate extension StaticString {
    static let notEnoughBytesForValue = "A value identifier was found, but the associated value could not be parsed" as StaticString
    static let notEnoughBytesForDocumentHeader = "Not enough bytes were remaining to parse a Document header" as StaticString
    static let notEnoughBytesForDocument = "There were not enough bytes left to match the length in the document header" as StaticString
    static let trailingBytes = "After parsing the Document, trailing bytes were found" as StaticString
    static let invalidBoolean = "A value other than 0x00 or 0x01 was used to represent a boolean" as StaticString
    static let incorrectDocumentTermination = "The 0x00 byte was not found where it should have been terminating a Document" as StaticString
}

extension Document {
    /// Validates this document's technical correctness
    ///
    /// If `validatingRecursively` is `true` the subdocuments will be traversed, too
    public func validate(recursively validatingRecursively: Bool = true) -> ValidationResult {
        // TODO: Update header if document is mutated
        
        var offset = 0
        let count = self.storage.usedCapacity
        
        func errorFound(reason: StaticString) -> ValidationResult {
            return ValidationResult(valid: false, errorPosition: offset, reason: reason)
        }
        
        guard count >= 4, var pointer = self.storage.readBuffer.baseAddress else {
            return errorFound(reason: .notEnoughBytesForDocument)
        }
        
        func advance(_ n: Int) {
            pointer += n
            offset = offset &+ n
        }
        
        func has(_ n: Int) -> Bool {
            return offset &+ n <= count
        }
        
        func document(array: Bool) -> ValidationResult {
            guard has(4) else {
                return errorFound(reason: .notEnoughBytesForDocumentHeader)
            }
            
            if validatingRecursively {
                let length = numericCast(pointer.int32) as Int
                
                guard has(length-1) else { // -1 because our BSON implementation does not have a null terminator in its internal storage
                    return errorFound(reason: .notEnoughBytesForDocument)
                }
                
                let document = Document(
                    storage: self.storage[offset ..< offset &+ length &- 1],
                    cache: DocumentCache(), // FIXME: Try to share sub-caches
                    isArray: array
                )
                
                var recursiveValidation = document.validate(recursively: true)
                
                guard recursiveValidation.valid else {
                    if let errorPosition = recursiveValidation.errorPosition {
                        recursiveValidation.errorPosition = errorPosition + offset
                    }
                    
                    return recursiveValidation
                }
            }
            
            advance(numericCast(pointer.int32))
            
            return .valid()
        }
        
        func string() -> Bool {
            guard has(4) else {
                return false
            }
            
            let stringLength: Int = numericCast(pointer.int32) &+ 4
            
            guard
                stringLength >= 5,
                offset &+ stringLength <= self.storage.usedCapacity,
                pointer[stringLength &- 1] == 0x00
            else {
                return false
            }
            
            // int32 contains the entire length, including null terminator
            advance(stringLength)
            
            return true
        }
        
        // + 1 for the missing null terminator
        // TODO: Re-enable this validation (validates the document header for having a correct length)
        // This is currently disabled, because we lazily update the document header
//        guard numericCast(pointer.int32) == count &+ 1 else {
//            return errorFound(reason: .notEnoughBytesForDocument)
//        }
        
        advance(4)
        
        // Iterate over key-value pairs.
        // Key is null terminated
        nextPair: while offset < count {
            let typeId = pointer.pointee
            
            advance(1)
            
            if typeId == 0x00 { // should not be present - the BSON implementation removes the null terminator
                return errorFound(reason: .incorrectDocumentTermination)
            }
            
            // Type
            guard let type = TypeIdentifier(rawValue: typeId) else {
                return errorFound(reason: "The type identifier found was unknown or unsupported")
            }
            
            // Key
            advance(storage.cString(at: offset))
            
            // Value
            switch type {
            case .double:
                advance(8)
            case .string:
                guard string() else {
                    return errorFound(reason: .notEnoughBytesForValue)
                }
            case .document, .array:
                let result = document(array: type == .array)
                
                guard result.valid else {
                    return result
                }
            case .binary:
                guard has(4) else {
                    return errorFound(reason: .notEnoughBytesForValue)
                }
                
                // int32 + subtype + bytes
                advance(numericCast(5 &+ pointer.int32))
            case .objectId:
                advance(12)
            case .boolean:
                guard pointer.pointee == 0x00 || pointer.pointee == 0x01 else {
                    return errorFound(reason: .invalidBoolean)
                }
                
                advance(1)
            case .datetime, .timestamp, .int64:
                guard has(8) else {
                    return errorFound(reason: .notEnoughBytesForValue)
                }
                
                advance(8)
            case .null, .minKey, .maxKey:
                // no data
                // Still need to check the key's size
                break
            case .regex:
                advance(storage.cString(at: offset))
                advance(storage.cString(at: offset))
            case .javascript, .javascriptWithScope:
                guard string() else {
                    return errorFound(reason: "Javascript code was found but the associated code could not be parsed")
                }
                
                if type == .javascriptWithScope {
                    let result = document(array: false)
                    
                    guard result.valid else {
                        return result
                    }
                }
            case .int32:
                guard has(4) else {
                    return errorFound(reason: "An int32 was found but not enough bytes are present")
                }
                
                advance(4)
            case .decimal128:
                advance(16)
            }
        }
        
        return offset == count ? .valid() : errorFound(reason: .trailingBytes)
    }
}
