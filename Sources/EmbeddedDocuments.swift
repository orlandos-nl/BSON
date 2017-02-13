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
        guard let `self` = self as? [String : BSONPrimitive] else {
            // `assertionFailure` only triggers a crash on debug configurations, not on release.
            assertionFailure("Only [String : BSONPrimitive] dictionaries are BSONPrimitive")
            return Document().makeBSONBinary()
        }
        
        let doc = Document(dictionaryElements: self.map { ($0, $1) })
        return doc.makeBSONBinary()
    }
}

extension Array : BSONPrimitive {
    public var typeIdentifier: UInt8 { return 0x04 }
    public func makeBSONBinary() -> [UInt8] {
        guard let `self` = self as? [BSONPrimitive] else {
            // `assertionFailure` only triggers a crash on debug configurations, not on release.
            assertionFailure("Only [BSONPrimitive] arrays are BSONPrimitive")
            return ([] as Document).makeBSONBinary()
        }
        
        let doc = Document(array: self)
        return doc.makeBSONBinary()
    }
}
