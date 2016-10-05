//
//  Document+DeveloperSupport.swift
//  BSON
//
//  Created by Robbert Brandsma on 17-08-16.
//
//

import Foundation


extension Document : CustomStringConvertible {
    /// The (debug) description of this Document
    public var description: String {
        return self.makeExtendedJSON()
    }
}

#if os(macOS) || os(iOS)
    extension Document : CustomPlaygroundQuickLookable {
        /// The Playground QuickLook version of this Document
        public var customPlaygroundQuickLook: PlaygroundQuickLook {
            return .text(self.makeExtendedJSON())
        }
    }
#endif
