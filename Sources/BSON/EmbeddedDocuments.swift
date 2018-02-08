//
//  EmbeddedDocuments.swift
//  BSON
//
//  Created by Robbert Brandsma on 13-02-17.
//
//

import Foundation

fileprivate protocol NilTestable {
    var isNil: Bool { get }
}
extension Optional : NilTestable {
    var isNil : Bool {
        return self == nil
    }
}

extension Dictionary : Primitive where Key == String, Value: Primitive {
    public var typeIdentifier: UInt8 { return 0x03 }
    public func makeBinary() -> Data {
        let doc = Document(dictionaryElements: self.map { pair in
            return (pair.key, pair.value)
        })
        
        return doc.makeBinary()
    }
}

extension Array : Primitive where Element: Primitive {
    public var typeIdentifier: UInt8 { return 0x04 }
    public func makeBinary() -> Data {
        return Document(array: self).makeBinary()
    }
}
