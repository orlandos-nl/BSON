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

extension Dictionary : Primitive {
    private func errorOut() {
        let error = "Only [String : BSON.Primitive] dictionaries are BSON.Primitive. Tried to initialize a document using [\(Key.self) : \(Value.self)]. This will crash on debug and print this message on release configurations."
        assertionFailure(error)
        print(error)
    }
    
    public var typeIdentifier: UInt8 { return 0x03 }
    public func makeBinary() -> Data {
        let doc = Document(dictionaryElements: self.flatMap {
            guard let key = $0.0 as? String else {
                errorOut()
                return nil
            }
            
            if let optional = $0.1 as? NilTestable, optional.isNil {
                return (key, nil)
            }
            
            guard let value = $0.1 as? Primitive else {
                errorOut()
                return nil
            }
            
            return (key, value)
        })
        return doc.makeBinary()
    }
}

extension Array : Primitive {
    public var typeIdentifier: UInt8 { return 0x04 }
    public func makeBinary() -> Data {
        if let `self` = self as? [Primitive] {
            return Document(array: self).makeBinary()
        } else if let `self` = self as? [Encodable] {
            let `self` = self.flatMap { value in
                return try? BSONEncoder().encodePrimitive(value)
            }
            
            return Document(array: self).makeBinary()
        } else {
            // `assertionFailure` only triggers a crash on debug configurations, not on release.
            let error = "Only [BSON.Primitive] arrays are BSON.Primitive. Tried to initialize a document using [\(Element.self)]. This will crash on debug and print this message on release configurations."
            assertionFailure(error)
            print(error)
            return ([] as Document).makeBinary()
        }
    }
}
