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
    public func makeExtendedJSON() -> String {
        var str: String
        if self.validatesAsArray() {
            str = self.makeIterator().map { $1.makeExtendedJSON() }.reduce("[") { "\($0),\($1)" } + "]"
        } else {
            str = self.makeIterator().map { pair in
                return "\"\(pair.key)\": \(pair.value.makeExtendedJSON())"
                }.reduce("{") { "\($0),\($1)" } + "}"
        }
        
        str.remove(at: str.index(after: str.startIndex)) // remove the comma
        return str
    }
}
