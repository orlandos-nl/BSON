//
//  Compatibility.swift
//  BSON
//
//  Created by Robbert Brandsma on 05-10-16.
//
//

import Foundation

#if os(macOS) || os(iOS)
typealias RegularExpression = NSRegularExpression
#endif
