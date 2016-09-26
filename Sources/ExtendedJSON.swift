//
//  ExtendedJSON.swift
//  BSON
//
//  Created by Robbert Brandsma on 14-06-16.
//
//

import Foundation

internal let isoDateFormatter: DateFormatter = {
    let fmt = DateFormatter()
    fmt.locale = Locale(identifier: "en_US_POSIX")
    fmt.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
    return fmt
}()

extension Value {
    /// Creates a JSON `String` from this `Value` formed as ExtendedJSON
    ///
    /// - returns: The JSON `String` representing the `Value`
    public func makeExtendedJSON() -> String {
        func escape(_ string: String) -> String {
            var string = string
            
            string = string.replacingOccurrences(of: "\\", with: "\\\\")
            string = string.replacingOccurrences(of: "\"", with: "\\\"")
            string = string.replacingOccurrences(of: "\u{8}", with: "\\b")
            string = string.replacingOccurrences(of: "\u{c}", with: "\\f")
            string = string.replacingOccurrences(of: "\n", with: "\\n")
            string = string.replacingOccurrences(of: "\r", with: "\\r")
            string = string.replacingOccurrences(of: "\t", with: "\\t")
            
            return string
        }
        
        switch self {
        case .double(let val):
            return String(val)
        case .string(let val):
            return "\"\(escape(val))\""
        case .document(let doc):
            return doc.makeExtendedJSON()
        case .array(let doc):
            return doc.makeExtendedJSON()
        case .binary(let subtype, let data):
            let base64 = Data(bytes: data).base64EncodedString()
            let subtype = String(subtype.rawValue, radix: 16).uppercased()
            return "{\"$binary\":\"\(base64)\",\"$type\":\"0x\(subtype)\"}"
        case .objectId(let id):
            return "{\"$oid\":\"\(id.hexString)\"}"
        case .boolean(let val):
            return val ? "true" : "false"
        case .dateTime(let date):
            let dateString = isoDateFormatter.string(from: date)
            return "{\"$date\":\"\(dateString)\"}"
        case .null:
            return "null"
        case .regularExpression(let pattern, let options):
            return "{\"$regex\":\"\(escape(pattern))\",\"$options\":\"\(escape(options))\"}"
        case .javascriptCode(let code):
            return "{\"$code\":\"\(escape(code))\"}"
        case .javascriptCodeWithScope(let code, let scope):
            return "{\"$code\":\"\(escape(code))\",\"$scope\":\(scope.makeExtendedJSON())}"
        case .int32(let val):
            return String(val)
        case .timestamp(let t, let i):
            return "{\"$timestamp\":{\"t\":\(t),\"i\":\(i)}}"
        case .int64(let val):
            return "{\"$numberLong\":\"\(val)\"}"
        case .minKey:
            return "{\"$minKey\":1}"
        case .maxKey:
            return "{\"$maxKey\":1}"
        case .nothing:
            return "{\"$undefined\":true}"
        }
    }
}

extension Document {
    /// All errors that can occur when parsing Extended JSON
    public enum ExtendedJSONError : Error {
        /// Invalid character at position
        case invalidCharacter(position: String.CharacterView.Index)
        
        /// -
        case unexpectedEndOfInput
        
        /// Expected a String at position at position
        case stringExpected(position: String.CharacterView.Index)
        
        /// Unable to parse the number at position
        case numberParseError(position: String.CharacterView.Index)
        
        /// Unable to parse the value at position
        case unparseableValue(position: String.CharacterView.Index)
    }
    
    /// Converts the `Document` to the [MongoDB extended JSON](https://docs.mongodb.com/manual/reference/mongodb-extended-json/) format.
    /// The data is converted to MongoDB extended JSON in strict mode.
    ///
    /// - returns: The JSON string. Depending on the type of document, the top level object will either be an array or object.
    public func makeExtendedJSON() -> String {
        var str: String
        if self.validatesAsArray() && isArray {
            str = self.makeIterator().map { pair in
                return pair.value.makeExtendedJSON()
                }.reduce("[") { "\($0),\($1)" } + "]"
        } else {
            str = self.makeIterator().map { pair in
                return "\"\(pair.key)\":\(pair.value.makeExtendedJSON())"
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
            // If at the ", skip it
            if try c() == "\"" {
                // Advance, so we are at the start of the string:
                advance()
            }
            
            // We will store the final string here:
            var string = ""
            
            characterLoop: while true {
                let char = try c()
                switch char {
                case "\"": // This is the end of the string.
                    break characterLoop
                case "\\": // Handle the escape sequence
                    if try checkLiteral("\\\"") { // Quotation mark, \"
                        string.append("\"")
                        continue characterLoop
                    } else if try checkLiteral("\\\\") { // Reverse solidus, \\
                        string.append("\\")
                        continue characterLoop
                    } else if try checkLiteral("\\r") { // Carriage return, \r
                        string.append("\r")
                        continue characterLoop
                    } else if try checkLiteral("\\n") { // Newline, \n
                        string.append("\n")
                        continue characterLoop
                    } else if try checkLiteral("\\/") { // Solidus, \/
                        string.append("/")
                        continue characterLoop
                    } else if try checkLiteral("\\b") { // Backspace, \b
                        string.append("\u{8}")
                        continue characterLoop
                    } else if try checkLiteral("\\f") { // Formfeed, \f
                        string.append("\u{c}")
                        continue characterLoop
                    } else if try checkLiteral("\\t") { // Horizontal tab, \t
                        string.append("\t")
                        continue characterLoop
                    } else if try checkLiteral("\\u") { // Unicode code, for example: \u000c or \u000C
                        // Get the four digits
                        guard json.distance(from: position, to: json.endIndex) >= 3 else {
                            string.append("\\u")
                            continue characterLoop
                        }
                        
                        let unicodeEnd = json.index(position, offsetBy: 3)
                        let substr = json[position...unicodeEnd]
                        
                        guard let code = Int(substr, radix: 16) else {
                            string.append("\\u")
                            continue characterLoop
                        }
                        
                        guard let scalar = UnicodeScalar(code) else {
                            continue characterLoop
                        }
                        let character = Character(scalar)
                        string.append(character)
                        continue characterLoop
                    } else {
                        fallthrough
                    }
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
            if remaining.hasPrefix(value) {
                position = json.index(position, offsetBy: value.characters.count)
                return true
            }
            
            return false
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
                    advance()
                default:
                    break
                }
                
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
            }
            
            subParser: if !isArray {
                // If this document is one of the extended JSON types, we should return the parsed value instead of an array or document.
                
                let count = document.count
                
                // For performance reasons, only do this if the count is 1 or 2, and only if the first key starts with a $.
                guard (count == 1 || count == 2) && document.keys[0].hasPrefix("$") else {
                    break subParser
                }
                
                if count == 1 {
                    if let hex = document["$oid"].stringValue {
                        // ObjectID
                        return try .objectId(ObjectId(hex))
                    } else if let dateString = document["$date"].stringValue {
                        // DateTime
                        if let date = parseISO8601(from: dateString) {
                            return .dateTime(date)
                        }
                    } else if let code = document["$code"].stringValue {
                        return .javascriptCode(code)
                    } else if let numberString = document["$numberLong"].stringValue {
                        guard let number = Int64(numberString) else {
                            break subParser
                        }
                        
                        return .int64(number)
                    } else if document["$minKey"] == 1 {
                        return .minKey
                    } else if document["$maxKey"] == 1 {
                        return .maxKey
                    } else if let timestamp = document["$timestamp"].documentValue, let t = timestamp["t"].int32Value, let i = timestamp["i"].int32Value {
                        return .timestamp(stamp: t, increment: i)
                    }
                } else if count == 2 {
                    if let base64 = document["$binary"].stringValue, let hexSubtype = document["$type"].stringValue {
                        // Binary
                        guard hexSubtype.characters.count > 2 else {
                            break subParser
                        }
                        
                        guard let data = Data(base64Encoded: base64), let subtypeInt = UInt8(hexSubtype[hexSubtype.index(hexSubtype.startIndex, offsetBy: 2)..<hexSubtype.endIndex], radix: 16) else {
                            break subParser
                        }
                        
                        let subtype = BinarySubtype(rawValue: subtypeInt)
                        
                        #if os(Linux)
                            var byteBuffer = [UInt8](repeating: 0, count: data.count)
                            data.copyBytes(to: &byteBuffer, count: byteBuffer.count)
                            return .binary(subtype: subtype, data: byteBuffer)
                        #else
                            return .binary(subtype: subtype, data: Array<UInt8>(data))
                        #endif
                    } else if let pattern = document["$regex"].stringValue, let options = document["$options"].stringValue {
                        // RegularExpression
                        return .regularExpression(pattern: pattern, options: options)
                    } else if let code = document["$code"].stringValue, let scope = document["$scope"].documentValue {
                        // JS with scope
                        return .javascriptCodeWithScope(code: code, scope: scope)
                    }
                }
            }
            
            return isArray ? .array(document) : .document(document)
        }
        
        let jsonVal = try parseObjectOrArray()
        self.init(data: jsonVal.document.bytes)
    }
}
