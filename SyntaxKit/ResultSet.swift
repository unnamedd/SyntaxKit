//
//  ResultSet.swift
//  SyntaxKit
//
//  Created by Sam Soffes on 10/11/14.
//  Copyright © 2014-2015 Sam Soffes. All rights reserved.
//

import Foundation

struct ResultSet {

    // MARK: - Properties

    private var _results = [Result]()
    var results: [Result] {
        return _results
    }

    var range: NSRange

    var isEmpty: Bool {
        return results.isEmpty
    }
    

    // MARK: - Initializers
    
    init(startingRange range: NSRange) {
        self.range = range
    }

    
    // MARK: - Adding
    
    mutating func extendWithRange(range: NSRange) {
        self.range = NSUnionRange(self.range, range)
    }

    mutating func addResult(result: Result) {
        _results.append(result)
        self.extendWithRange(result.range)
    }

    mutating func addResults(resultSet: ResultSet) {
        self.extendWithRange(resultSet.range)
        for result in resultSet.results {
            _results.append(result)
        }
    }
}
