//
//  ArrayDictionaryDocument.swift
//  BSON
//
//  Created by Joannis Orlandos on 01/02/16.
//  Copyright © 2016 Robbert Brandsma. All rights reserved.
//

import Foundation

internal protocol BSONArrayConversionProtocol : AbstractBSONBase {
    func getAbstractArray() -> [AbstractBSONBase]
}

internal protocol BSONDictionaryConversionProtocol : AbstractBSONBase {
    func getAbstractDictionary() -> [String: AbstractBSONBase]
}

extension Array : BSONArrayConversionProtocol {
    func getAbstractArray() -> [AbstractBSONBase] {
        return self.flatMap { $0 as? AbstractBSONBase }
    }
}

extension Dictionary : BSONDictionaryConversionProtocol {
    func getAbstractDictionary() -> [String : AbstractBSONBase] {
        var d = [String:AbstractBSONBase]()
        for (k,v) in self {
            guard let k = k as? String, abstractV = v as? AbstractBSONBase else {
                print("ERREUR: \(v.dynamicType)")
                return d
            }
            d[k] = abstractV
        }
        return d
    }
}

/// The prefix * operator will be deprecated as soon as it isn't needed anymore.
/// The reason for adding the operator is that the Swift compiler sometimes likes to create NSArrays where it should be creating Swift Arrays.
prefix operator * { }

/// Prefix * operator for Dictionaries
public prefix func *(input: [String : AbstractBSONBase]) -> [String : AbstractBSONBase] {
    // 🖕, Swift!
    return input
}

/// Prefix * operator for arrays
public prefix func *(input: [AbstractBSONBase]) -> [AbstractBSONBase] {
    // 🖕, Swift!
    return input
}