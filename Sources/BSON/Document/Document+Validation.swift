import NIO

public struct ValidationResult {
    public internal(set) var errorPosition: Int?
    public let reason: String?
    public let key: String?
    
    public var isValid: Bool {
        return errorPosition == nil && reason == nil
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
    static func validate(buffer: ByteBuffer, asArray validateAsArray: Bool) -> ValidationResult {
        var currentIndex = 0

        func errorFound(reason: String, key: String? = nil) -> ValidationResult {
            return ValidationResult(errorPosition: currentIndex, reason: reason, key: key)
        }
        
        /// Moves the readerIndex by `amount` if at least that many bytes are present
        /// Returns `false` if the operation was unsuccessful
        func has(_ amount: Int) -> Bool {
            guard buffer.readableBytes > currentIndex + amount else {
                return false
            }

            currentIndex += amount
            return true
        }
        
        func hasString() -> Bool {
            guard let stringLengthWithNull = buffer.getInteger(at: currentIndex, endianness: .little, as: Int32.self) else {
                return false
            }
            
            guard stringLengthWithNull >= 1 else {
                return false
            }

            currentIndex += 4
            
            // check if string content present
            guard buffer.getString(at: currentIndex, length: Int(stringLengthWithNull) &- 1) != nil else {
                return false
            }

            currentIndex += Int(stringLengthWithNull)
            
            guard buffer.getInteger(at: currentIndex - 1, endianness: .little, as: UInt8.self) == 0 else {
                return false
            }

            return true
        }
        
        /// Moves the reader index past the CString and returns `true` if a CString (null terminated string) is present
        func hasCString() -> Bool {
            guard let length = buffer.firstRelativeIndexOf(startingAt: currentIndex) else {
                return false
            }

            currentIndex += length + 1
            return true
        }
        
        func validateDocument(array: Bool) -> ValidationResult {
            guard let documentLength = buffer.getInteger(at: currentIndex, endianness: .little, as: Int32.self) else {
                return errorFound(reason: .notEnoughBytesForDocumentHeader)
            }
            
            guard documentLength > 0 else {
                return errorFound(reason: "Negative subdocument length")
            }
            
            guard let subBuffer = buffer.getSlice(at: currentIndex, length: Int(documentLength)) else {
                return errorFound(reason: .notEnoughBytesForValue)
            }
            
            var recursiveValidation = Document.validate(buffer: subBuffer, asArray: array)
            currentIndex += Int(documentLength)
            
            guard recursiveValidation.isValid else {
                if let errorPosition = recursiveValidation.errorPosition {
                    recursiveValidation.errorPosition = errorPosition + currentIndex
                }
                
                return recursiveValidation
            }
            
            return .valid()
        }

        // Extract the document header
        guard let numberOfBytesFromHeader = buffer.getInteger(at: currentIndex, endianness: .little, as: Int32.self) else {
            return errorFound(reason: .notEnoughBytesForDocumentHeader)
        }

        currentIndex += 4

        // Validate that the number of bytes is correct
        guard Int(numberOfBytesFromHeader) == buffer.readableBytes else { // +4 because the header is already parsed
            return errorFound(reason: .notEnoughBytesForDocument)
        }
        
        // Validate document contents
        while buffer.readableBytes > 1 {
            guard let typeId = buffer.getInteger(at: currentIndex, endianness: .little, as: UInt8.self) else {
                return errorFound(reason: .notEnoughBytesForValue)
            }

            guard let typeIdentifier = TypeIdentifier(rawValue: typeId) else {
                if typeId == 0x00, currentIndex + 1 == Int(numberOfBytesFromHeader) {
                    return .valid()
                }

                return errorFound(reason: "The type identifier \(typeId) is not valid")
            }

            currentIndex += 1

            /// Check for key
            guard let keyLengthWithoutNull = buffer.firstRelativeIndexOf(startingAt: currentIndex) else {
                return errorFound(reason: "Could not parse the element key")
            }
            
            let key = buffer.getString(at: currentIndex, length: keyLengthWithoutNull)
            currentIndex += keyLengthWithoutNull + 1
            
//            if validateAsArray {
//                guard key == "\(currentIndex)" else {
//                    return errorFound(reason: "The document should be an array, but the element key does not have the expected value of \(currentIndex)", key: key)
//                }
//            }

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
                
                guard result.isValid else {
                    return result
                }
            case .binary:
                guard let numberOfBytes = buffer.getInteger(at: currentIndex, endianness: .little, as: Int32.self) else {
                    return errorFound(reason: .notEnoughBytesForValue, key: key)
                }

                currentIndex += 4

                // Binary type
                guard buffer.getInteger(at: currentIndex, endianness: .little, as: UInt8.self) != nil else {
                    return errorFound(reason: .notEnoughBytesForValue, key: key)
                }
                
                currentIndex += 1

                guard has(Int(numberOfBytes)) else {
                    return errorFound(reason: .notEnoughBytesForValue, key: key)
                }
            case .objectId:
                guard has(12) else {
                    return errorFound(reason: .notEnoughBytesForValue, key: key)
                }
            case .boolean:
                guard let value = buffer.getInteger(at: currentIndex, endianness: .little, as: UInt8.self) else {
                    return errorFound(reason: .notEnoughBytesForValue, key: key)
                }

                currentIndex += 1
                
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
                guard let size = buffer.getInteger(at: currentIndex, endianness: .little, as: Int32.self) else {
                    return errorFound(reason: .notEnoughBytesForValue, key: key)
                }

                let finalOffset = currentIndex + Int(size)
                currentIndex += 4

                guard hasString() else {
                    return errorFound(reason: "Could not parse JavascriptCode (with scope) string", key: key)
                }
                
                // validate scope document
                let result = validateDocument(array: false)
                
                guard result.isValid else {
                    return result
                }
                
                guard currentIndex == finalOffset else {
                    return errorFound(reason: .notEnoughBytesForValue, key: key)
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
        guard buffer.getInteger(at: currentIndex, endianness: .little, as: UInt8.self) == 0 else {
            return errorFound(reason: .incorrectDocumentTermination)
        }
        
        return .valid()
    }
    
    /// Validates this document's technical correctness
    ///
    /// If `validatingRecursively` is `true` the subdocuments will be traversed, too
    public func validate() -> ValidationResult {
        return Document.validate(buffer: storage, asArray: self.isArray)
    }
}
