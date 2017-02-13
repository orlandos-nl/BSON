//
//  EmbeddedDocuments.swift
//  BSON
//
//  Created by Robbert Brandsma on 13-02-17.
//
//

import Foundation

extension Dictionary : BSONPrimitive {
    public var typeIdentifier: UInt8 { return 0x03 }
    public func makeBSONBinary() -> [UInt8] {
        guard let dict = self as? [String : BSONPrimitive] else {
            // `assertionFailure` only triggers a crash on debug configurations, not on release.
            let error = "Only [String : BSONPrimitive] dictionaries are BSONPrimitive. Tried to initialize a document using [\(Key.self) : \(Value.self)]. This will crash on debug and print this message on release configurations."
            assertionFailure(error)
            print(error)
            return Document().makeBSONBinary()
        }
        
        let doc = Document(dictionaryElements: dict.map { ($0, $1) })
        return doc.makeBSONBinary()
    }
}

extension Array : BSONPrimitive {
    public var typeIdentifier: UInt8 { return 0x04 }
    public func makeBSONBinary() -> [UInt8] {
        guard let `self` = self as? [BSONPrimitive] else {
            // `assertionFailure` only triggers a crash on debug configurations, not on release.
            let error = "Only [BSONPrimitive] arrays are BSONPrimitive. Tried to initialize a document using [\(Element.self)]. This will crash on debug and print this message on release configurations."
            assertionFailure(error)
            print(error)
            return ([] as Document).makeBSONBinary()
        }
        
        let doc = Document(array: self)
        return doc.makeBSONBinary()
    }
}
