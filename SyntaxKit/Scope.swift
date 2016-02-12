//
//  Scope.swift
//  SyntaxKit
//
//  Created by Alexander Hedges on 10/02/16.
//  Copyright © 2016 Sam Soffes. All rights reserved.
//

import Foundation

class Scope: Result {
    
    // MARK: - Properties
    
    let attribute: AnyObject?
    
    
    // MARK: - Initializers
    
    init(identifier: String, range: NSRange, attribute: AnyObject? = nil) {
        self.attribute = attribute
        super.init(identifier: identifier, range: range)
    }
}
