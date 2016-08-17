//
//  Document+DeveloperSupport.swift
//  BSON
//
//  Created by Robbert Brandsma on 17-08-16.
//
//

import Foundation


extension Document : CustomStringConvertible {
    public var description: String {
        return self.makeExtendedJSON()
    }
}

#if os(OSX) || os(iOS)
    extension Document : CustomPlaygroundQuickLookable {
        public var customPlaygroundQuickLook: PlaygroundQuickLook {
            return .text(self.makeExtendedJSON())
        }
    }
#endif
