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

	var range: NSRange?

	var isEmpty: Bool {
		return results.isEmpty
	}
    
    // MARK: - Comparing
    
    func hasLowerPriorityThan(other: ResultSet?) -> Bool {
        if other == nil || other!.range == nil {
            return false
        } else if self.range == nil {
            return true
        }  else if self.range!.location != other!.range!.location {
            return self.range!.location > other!.range!.location
        } else {
            return self.range!.length < other!.range!.length
        }
    }

	// MARK: - Adding

	mutating func addResult(result: Result) {
		_results.append(result)

		guard let range = range else {
			self.range = result.range
			return
		}

		self.range = NSUnionRange(range, result.range)
	}

	mutating func addResults(resultSet: ResultSet) {
		for result in resultSet.results {
			addResult(result)
		}
	}
}
