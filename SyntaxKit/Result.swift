//
//  Result.swift
//  SyntaxKit
//
//  Created by Sam Soffes on 10/11/14.
//  Copyright © 2014-2015 Sam Soffes. All rights reserved.
//

import Foundation

class Result: Equatable {

    // MARK: - Properties

    let patternIdentifier: String
    var range: NSRange


    // MARK: - Initializers

    init(identifier: String, range: NSRange) {
        self.patternIdentifier = identifier
        self.range = range
    }
}

func ==(lhs: Result, rhs: Result) -> Bool {
    return lhs.patternIdentifier == rhs.patternIdentifier && lhs.range.toRange() == rhs.range.toRange()
}
