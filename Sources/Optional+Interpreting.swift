//
//  Optional+Interpreting.swift
//  BSON
//
//  Created by Robbert Brandsma on 13-02-17.
//
//

import Foundation

extension Optional where Wrapped == ValueConvertible {
    
    var interpreted: Double? {
        if let num = self as? Int32 {
            return Double(num)
        } else if let num = self as? Int {
            return Double(num)
        } else if let num = self as? Double {
            return Double(num)
        } else if let num = self as? String {
            return Double(num)
        }
        
        return nil
    }
}
