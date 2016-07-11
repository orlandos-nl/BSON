//
//  Value-Subscript.swift
//  BSON
//
//  Created by Robbert Brandsma on 18-04-16.
//
//

import Foundation

extension Value {
    public subscript(key: String) -> Value {
        get {
            switch self {
            case .document(let subdoc):
                return subdoc[key]
            case .array(let subdoc):
                return subdoc[key]
            default:
                return .nothing
            }
        }
        
        set {
            switch self {
            case .document(var subdoc):
                subdoc[key] = newValue
                self = .document(subdoc)
            case .array(var subdoc):
                subdoc[key] = newValue
                self = .array(subdoc)
            default:
                var document: Document = [:]
                document[key] = newValue
                self = .document(document)
            }
        }
    }
    
    public subscript(key: Int) -> Value {
        get {
            switch self {
            case .document(let subdoc):
                return subdoc[key]
            case .array(let subdoc):
                return subdoc[key]
            default:
                return .nothing
            }
        }
        
        set {
            switch self {
            case .document(var subdoc):
                subdoc[key] = newValue
                self = .document(subdoc)
            case .array(var subdoc):
                subdoc[key] = newValue
                self = .array(subdoc)
            default:
                self = .array(["\(key)": newValue])
            }
        }
    }
}
