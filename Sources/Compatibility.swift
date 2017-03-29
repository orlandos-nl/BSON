//
//  Compatibility.swift
//  BSON
//
//  Created by Robbert Brandsma on 05-10-16.
//
//

import Foundation

#if os(macOS) || os(iOS) || swift(>=3.1)
public typealias RegularExpression = NSRegularExpression
#endif
