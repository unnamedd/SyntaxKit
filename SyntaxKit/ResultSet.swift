//
//  ResultSet.swift
//  SyntaxKit
//
//  Created by Sam Soffes on 10/11/14.
//  Copyright © 2014-2015 Sam Soffes. All rights reserved.
//

class ResultSet {
    
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
    
    func extendWithRange(range: NSRange) {
        _range = NSUnionRange(self.range, range)
    }
    
    func addResult(result: Result) {
        _results.append(result)
        extendWithRange(result.range)
    }
    
    func addResults(resultSet: ResultSet) {
        extendWithRange(resultSet.range)
        for result in resultSet.results {
            _results.append(result)
        }
    }
}
