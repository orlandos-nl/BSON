//
//  ExtendedJSON.swift
//  BSON
//
//  Created by Robbert Brandsma on 14-06-16.
//
//

import Foundation

extension Value {
    public func makeExtendedJSON() -> String {
        switch self {
        case .double(let val):
            return String(val)
        case .string(let val):
            return "\"\(val)\""
        case .document(let doc):
            return doc.makeExtendedJSON()
        case .array(let doc):
            return doc.makeExtendedJSON()
        case .binary(let subtype, let data):
            let base64 = Data(bytes: data).base64EncodedString()
            let subtype = String(subtype.rawValue, radix: 16).uppercased()
            return "{\"$binary\": \"\(base64)\", \"$type\": \"0x\(subtype)\"}"
        case .objectId(let id):
            return "{\"$oid\": \"\(id.hexString)\"}"
        case .boolean(let val):
            return val ? "true" : "false"
        case .dateTime(let date):
            if #available(OSX 10.12, *) {
                let date = ISO8601DateFormatter.string(from: date, timeZone: TimeZone.default(), formatOptions: [.withFullDate, .withFullTime, .withTimeZone])
                return "{\"$date\": \"\(date)\"}"
            } else {
                let error = "\"Unsupported: BSON does not support converting DateTime to JSON on this platform.\""
                print(error)
                return error
            }
        case .null:
            return "null"
        case .regularExpression(let pattern, let options):
            return "{\"$regex\": \"\(pattern)\", \"$options\": \"\(options)\"}"
        case .javascriptCode(let code):
            return "{\"$code\": \"\(code)\"}"
        case .javascriptCodeWithScope(let code, let scope):
            return "{\"$code\": \"\(code)\", \"$scope\": \(scope.makeExtendedJSON())}"
        case .int32(let val):
            return String(val)
        case .timestamp(_):
            fatalError("Timestamp JSON conversion not implemented")
        case .int64(let val):
            return "{\"$numberLong\": \"\(val)\"}"
        case .minKey:
            return "{\"$minKey\": 1}"
        case .maxKey:
            return "{\"$maxKey\": 1}"
        case .nothing:
            return "{\"$undefined\": true}"
        }
    }
}

extension Document {
    
    enum ExtendedJSONError : ErrorProtocol {
        case invalidCharacter(position: String.CharacterView.Index)
        case unexpectedEndOfInput
        case stringExpected(position: String.CharacterView.Index)
        case numberParseError(position: String.CharacterView.Index)
        case unparseableValue(position: String.CharacterView.Index)
    }
    
    /// Converts the `Document` to the [MongoDB extended JSON](https://docs.mongodb.com/manual/reference/mongodb-extended-json/) format.
    /// The data is converted to MongoDB extended JSON in strict mode.
    ///
    /// - returns: The JSON string. Depending on the type of document, the top level object will either be an array or object.
    public func makeExtendedJSON() -> String {
        var str: String
        if self.validatesAsArray() {
            str = self.makeIterator().map { pair in
                return pair.value.makeExtendedJSON()
                }.reduce("[") { "\($0),\($1)" } + "]"
        } else {
            str = self.makeIterator().map { pair in
                return "\"\(pair.key)\": \(pair.value.makeExtendedJSON())"
                }.reduce("{") { "\($0),\($1)" } + "}"
        }
        
        if (str.characters.count > 2) {
            str.remove(at: str.index(after: str.startIndex)) // remove the comma
        }
        return str
    }
    
    
    /// Parses the given JSON string as [MongoDB extended JSON](https://docs.mongodb.com/manual/reference/mongodb-extended-json/).
    /// The data is parsed in strict mode.
    ///
    /// - parameter json: The MongoDB extended JSON string. The top level object must be an array or object.
    ///
    /// - throws: May throw any error that `Foundation.JSONSerialization` throws.
    public init(extendedJSON json: String) throws {
        // We will parse the JSON directly into the BSON binary format. This will be our buffer:
        let bsonBytes: [UInt8] = []
        
        let characters = json.characters
        var position = characters.startIndex
        
        /// Advances one position
        func advance() {
            position = characters.index(after: position)
        }
        
        /// Returns the character at the current position
        ///
        /// - throws: Throws when the current character is out of bounds.
        ///
        /// - returns: The character at the current position.
        func c() throws -> Character {
            if position < characters.endIndex {
                return characters[position]
            } else {
                throw ExtendedJSONError.unexpectedEndOfInput
            }
        }

        /// Increase the position to the first character found that is not whitespace.
        ///
        /// - throws: Throws when a character is out of bounds.
        func skipWhitespace() throws {
            while true {
                switch try c() {
                case " ", "\n", "\t":
                    advance()
                default:
                    return
                }
            }
        }
        
        
        /// Get the string at the current position.
        /// After calling this, the position will be increased until the character after the closing ".
        ///
        /// - throws: Can throw when a bounds error occurs.
        ///
        /// - returns: The string
        func getStringValue() throws -> String {
            // Of course, a string should start with "
            guard try c() == "\"" else {
                throw ExtendedJSONError.stringExpected(position: position)
            }
            
            // Advance, so we are at the start of the string:
            advance()
            
            // We will store the final string here:
            var string = ""
            
            characterLoop: while true {
                let char = try c()
                switch char {
                case "\"": // This is the end of the string.
                    break characterLoop
                case "\\": // Handle the escape sequence
                    // TODO: Implement JSON escape sequences
                    fatalError("JSON escape sequences are not yet implemented.")
                default:
                    string.append(char)
                }
                
                advance()
            }
            
            // Advance past the end of the string:
            advance()
            
            return string
        }
        
        
        /// Checks if the given literal is at the current position.
        /// After calling this, the position will be after the literal if it was found, or unaltered if it wasn't.
        ///
        /// - parameter value: The literal to check for.
        ///
        /// - throws: Unexpected end of document
        ///
        /// - returns: True when the literal is found, false otherwise.
        func checkLiteral(_ value: String) throws -> Bool {
            let endIndex = json.index(position, offsetBy: value.characters.count)
            if endIndex > json.endIndex {
                return false
            }
            
            let remaining = json[position..<json.endIndex]
            return remaining.hasPrefix(value)
        }
        
        /// Parse the object at array at the current position. After calling this, the position will be after the end of the object or array.
        func parseObjectOrArray() throws -> Value {
            // This will be the document we're working with
            var document = Document()
            
            // There may be whitespace before the start of the object or array
            try skipWhitespace()
            
            // Check if this is an array or object
            let isArray: Bool
            switch try c() {
            case "{":
                isArray = false
            case "[":
                isArray = true
            default:
                throw ExtendedJSONError.invalidCharacter(position: position)
            }
            
            // Advance past the starting character
            advance()
            
            // Loop over the characters until we get to the end
            valueFindLoop: while true {
                // Whitespace, whitespace everywhere!
                try skipWhitespace()
                
                // Get the key, which may be the current index in the case of an array, or a string.
                let key: String? = isArray ? nil : try getStringValue()
                
                // We are now after the key, so we should skip whitespace again.
                try skipWhitespace()
                
                // In case of an object, the next character should be a colon (:)
                if !isArray {
                    guard try c() == ":" else {
                        throw ExtendedJSONError.invalidCharacter(position: position)
                    }
                    
                    advance()
                    try skipWhitespace()
                }
                
                // We are now at the start of the value. We will now get the value and type identifier.
                let value: Value
                switch try c() {
                case "\"":
                    // This is a string
                    value = .string(try getStringValue())
                case "{", "[":
                    // This is an object or array
                    value = try parseObjectOrArray()
                case "-", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9":
                    // TODO: support these e+24 numbers
                    let numberStart = position
                    
                    let numberCharacters = ["-", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "."]
                    while numberCharacters.contains(String(try c())) {
                        advance()
                    }
                
                    let numberString = json[numberStart..<position]
                    
                    // Determine the type: default to int32, but if it contains a ., double
                    if numberString.contains(".") {
                        guard let number = Double(numberString) else {
                            throw ExtendedJSONError.numberParseError(position: numberStart)
                        }
                        
                        value = .double(number)
                    } else {
                        guard let number = Int32(numberString) else {
                            throw ExtendedJSONError.numberParseError(position: numberStart)
                        }
                        
                        value = .int32(number)
                    }
                case _ where try checkLiteral("true"):
                    value = .boolean(true)
                case _ where try checkLiteral("false"):
                    value = .boolean(false)
                case _ where try checkLiteral("null"):
                    value = .null
                default:
                    throw ExtendedJSONError.unparseableValue(position: position)
                }
                
                // All the information to be able to append to the document is now ready:
                if let key = key {
                    document.append(value, forKey: key)
                } else {
                    document.append(value)
                }
                
                // We are now after the value. Skip whitespace, and then determine the next action.
                try skipWhitespace()
                
                switch try c() {
                case "}":
                    guard !isArray else {
                        throw ExtendedJSONError.invalidCharacter(position: position)
                    }
                    
                    advance()
                    break valueFindLoop
                case "]":
                    guard isArray else {
                        throw ExtendedJSONError.invalidCharacter(position: position)
                    }
                    
                    advance()
                    break valueFindLoop
                case ",":
                    continue valueFindLoop
                default:
                    throw ExtendedJSONError.invalidCharacter(position: position)
                }
            }
            
            return isArray ? .array(document) : .document(document)
        }

        let jsonVal = try parseObjectOrArray()
        self.init(data: jsonVal.documentValue!.bytes)
    }
}
