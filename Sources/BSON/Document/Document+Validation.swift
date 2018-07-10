import NIO

public struct ValidationResult {
    public internal(set) var errorPosition: Int?
    public let reason: String?
    public let key: String?
    
    public var valid: Bool {
        return errorPosition != nil && reason != nil
    }
    
    static func valid() -> ValidationResult {
        return ValidationResult(errorPosition: nil, reason: nil, key: nil)
    }
}

fileprivate extension String {
    static let notEnoughBytesForValue = "A value identifier was found, but the associated value could not be parsed"
    static let notEnoughBytesForDocumentHeader = "Not enough bytes were remaining to parse a Document header"
    static let notEnoughBytesForDocument = "There were not enough bytes left to match the length in the document header"
    static let trailingBytes = "After parsing the Document, trailing bytes were found"
    static let invalidBoolean = "A value other than 0x00 or 0x01 was used to represent a boolean"
    static let incorrectDocumentTermination = "The 0x00 byte was not found where it should have been terminating a Document"
}

extension Document {
    /// Validates the given `buffer` as a Document
    static func validate(buffer: inout ByteBuffer, asArray validateAsArray: Bool) -> ValidationResult {
        func errorFound(reason: String, key: String? = nil) -> ValidationResult {
            return ValidationResult(errorPosition: buffer.readerIndex, reason: reason, key: key)
        }
        
        /// Moves the readerIndex by `amount` if at least that many bytes are present
        /// Returns `false` if the operation was unsuccessful
        func has(_ amount: Int) -> Bool {
            guard buffer.readableBytes > amount else {
                return false
            }
            
            buffer.moveReaderIndex(forwardBy: amount)
            
            return true
        }
        
        func hasString() -> Bool {
            guard let stringLength = buffer.readInteger(endianness: .little, as: Int32.self) else {
                return false
            }
            
            // check if string content present
            guard buffer.readString(length: Int(stringLength) &- 1) != nil else {
                return false
            }
            
            guard buffer.readInteger(endianness: .little, as: UInt8.self) == 0 else {
                return false
            }
            
            return true
        }
        
        /// Moves the reader index past the CString and returns `true` if a CString (null terminated string) is present
        func hasCString() -> Bool {
            guard let nullTerminatorIndex = buffer.readableBytesView.firstIndex(of: 0) else {
                return false
            }
            
            buffer.moveReaderIndex(forwardBy: nullTerminatorIndex + 1)
            
            return true
        }
        
        func validateDocument(array: Bool) -> ValidationResult {
            let documentOffset = buffer.readerIndex
            guard let documentLength = buffer.getInteger(at: documentOffset, endianness: .little, as: Int32.self) else {
                return errorFound(reason: .notEnoughBytesForDocumentHeader)
            }
            
            guard var subBuffer = buffer.readSlice(length: Int(documentLength)) else {
                return errorFound(reason: .notEnoughBytesForValue)
            }
            
            var recursiveValidation = Document.validate(buffer: &subBuffer, asArray: array)
            
            guard recursiveValidation.valid else {
                if let errorPosition = recursiveValidation.errorPosition {
                    recursiveValidation.errorPosition = errorPosition + documentOffset
                }
                
                return recursiveValidation
            }
            
            return .valid()
        }
        
        // Extract the document header
        guard let numberOfBytesFromHeader = buffer.readInteger(endianness: .little, as: Int32.self) else {
            return errorFound(reason: .notEnoughBytesForDocumentHeader)
        }
        
        // Validate that the number of bytes is correct
        guard Int(numberOfBytesFromHeader) == buffer.readableBytes + 4 else { // +4 because the header is already parsed
            return errorFound(reason: .notEnoughBytesForDocument)
        }
        
        var currentIndex = 0
        
        // Validate document contents
        while buffer.readableBytes > 1 {
            defer { currentIndex += 1 }
            
            guard let typeId = buffer.readInteger(endianness: .little, as: UInt8.self) else {
                return errorFound(reason: .notEnoughBytesForValue)
            }
            
            guard let typeIdentifier = TypeIdentifier(rawValue: typeId) else {
                return errorFound(reason: "The type identifier \(typeId) is not valid")
            }
            
            /// Check for key
            guard let nullTerminatorIndex = buffer.readableBytesView.firstIndex(of: 0) else {
                return errorFound(reason: "Could not parse the element key")
            }
            
            let key = buffer.readString(length: buffer.readableBytes - nullTerminatorIndex)
            
            if validateAsArray {
                guard key == "\(currentIndex)" else {
                    return errorFound(reason: "The document should be an array, but the element key does not have the expected value of \(currentIndex)", key: key)
                }
            }
            
            switch typeIdentifier {
            case .double:
                guard has(8) else {
                    return errorFound(reason: .notEnoughBytesForValue, key: key)
                }
            case .string:
                guard hasString() else {
                    return errorFound(reason: .notEnoughBytesForValue, key: key)
                }
            case .document, .array:
                let result = validateDocument(array: typeIdentifier == .array)
                
                guard result.valid else {
                    return result
                }
            case .binary:
                guard let numberOfBytes = buffer.readInteger(endianness: .little, as: Int32.self), buffer.readInteger(endianness: .little, as: UInt8.self) != nil, has(Int(numberOfBytes)) else {
                    return errorFound(reason: .notEnoughBytesForValue, key: key)
                }
            case .objectId:
                guard has(12) else {
                    return errorFound(reason: .notEnoughBytesForValue, key: key)
                }
            case .boolean:
                guard let value = buffer.readInteger(endianness: .little, as: UInt8.self) else {
                    return errorFound(reason: .notEnoughBytesForValue, key: key)
                }
                
                guard value == 0x00 || value == 0x01 else {
                    return errorFound(reason: .invalidBoolean, key: key)
                }
            case .datetime, .timestamp, .int64:
                guard has(8) else {
                    return errorFound(reason: .notEnoughBytesForValue, key: key)
                }
            case .null, .minKey, .maxKey:
                // no data
                break
            case .regex:
                guard hasCString() && hasCString() else {
                    return errorFound(reason: "The regular expression is malformed", key: key)
                }
            case .javascript:
                guard hasString() else {
                    return errorFound(reason: "Could not parse JavascriptCode string", key: key)
                }
            case .javascriptWithScope:
                guard buffer.readInteger(endianness: .little, as: Int32.self) != nil else {
                    return errorFound(reason: .notEnoughBytesForValue, key: key)
                }
                
                guard hasString() else {
                    return errorFound(reason: "Could not parse JavascriptCode (with scope) string", key: key)
                }
                
                // validate scope document
                let result = validateDocument(array: false)
                
                guard result.valid else {
                    return result
                }
            case .int32:
                guard has(4) else {
                    return errorFound(reason: .notEnoughBytesForValue, key: key)
                }
            case .decimal128:
                guard has(16) else {
                    return errorFound(reason: .notEnoughBytesForValue, key: key)
                }
            }
        }
        
        // Check the terminator
        guard buffer.readInteger(endianness: .little, as: UInt8.self) == 0 else {
            return errorFound(reason: .incorrectDocumentTermination)
        }
        
        return .valid()
    }
    
    /// Validates this document's technical correctness
    ///
    /// If `validatingRecursively` is `true` the subdocuments will be traversed, too
    public func validate() -> ValidationResult {
        var buffer = self.makeByteBuffer()
        return Document.validate(buffer: &buffer, asArray: self.isArray)
    }
}
