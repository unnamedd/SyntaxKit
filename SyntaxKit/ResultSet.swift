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
    
    var results: [Result]   { return _results }
    var range: NSRange      { return _range }
    
    private var _results = [Result]()
    private var _range: NSRange
    
    
    // MARK: - Initializers
    
    init(startingRange range: NSRange) {
        _range = range
    }
    
    
    // MARK: - Adding
    
    mutating func extendWithRange(range: NSRange) {
        _range = NSUnionRange(self.range, range)
    }
    
    mutating func addResult(result: Result) {
        _results.append(result)
        extendWithRange(result.range)
    }
    
    mutating func addResults(resultSet: ResultSet) {
        extendWithRange(resultSet.range)
        for result in resultSet.results {
            _results.append(result)
        }
    }
}
