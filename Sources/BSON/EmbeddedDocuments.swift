//
//  EmbeddedDocuments.swift
//  BSON
//
//  Created by Robbert Brandsma on 13-02-17.
//
//

import KittenCore
import Foundation

extension Dictionary : Primitive {
    public var typeIdentifier: Byte { return 0x03 }
    public func makeBinary() -> Bytes {
        guard Key.self == String.self && Value.self is Primitive.Type else {
            // `assertionFailure` only triggers a crash on debug configurations, not on release.
            let error = "Only [String : BSON.Primitive] dictionaries are BSON.Primitive. Tried to initialize a document using [\(Key.self) : \(Value.self)]. This will crash on debug and print this message on release configurations."
            assertionFailure(error)
            print(error)
            return Document().makeBinary()
        }
        
        let doc = Document(dictionaryElements: self.map { ($0.0 as! String, $0.1 as? Primitive) })
        return doc.makeBinary()
    }
}

extension Array : Primitive {
    public var typeIdentifier: Byte { return 0x04 }
    public func makeBinary() -> Bytes {
        guard let `self` = self as? [Primitive] else {
            // `assertionFailure` only triggers a crash on debug configurations, not on release.
            let error = "Only [BSON.Primitive] arrays are BSON.Primitive. Tried to initialize a document using [\(Element.self)]. This will crash on debug and print this message on release configurations."
            assertionFailure(error)
            print(error)
            return ([] as Document).makeBinary()
        }
        
        let doc = Document(array: self)
        return doc.makeBinary()
    }
}
