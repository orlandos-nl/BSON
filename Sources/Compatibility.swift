//
//  Compatibility.swift
//  BSON
//
//  Created by Robbert Brandsma on 05-10-16.
//
//

import Foundation

#if os(macOS) || os(iOS)
public typealias RegularExpression = NSRegularExpression
#endif
