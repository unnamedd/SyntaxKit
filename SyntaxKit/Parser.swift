//
//  Parser.swift
//  SyntaxKit
//
//  Created by Sam Soffes on 9/19/14.
//  Copyright © 2014-2015 Sam Soffes. All rights reserved.
//

import Foundation

public class Parser {

	// MARK: - Types

	public typealias Callback = (scope: String, range: NSRange) -> Void


	// MARK: - Properties

	public let language: Language


	// MARK: - Initializers

	public init(language: Language) {
		self.language = language
	}


	// MARK: - Parsing

	public func parse(string: String, match callback: Callback) {
		// Loop through paragraphs
		let s: NSString = string
		let length = s.length
		var paragraphEnd = 0

		while paragraphEnd < length {
            let paragraphStart = paragraphEnd
            var newParagraphStart = 0
			s.getParagraphStart(&newParagraphStart, end: &paragraphEnd, contentsEnd: nil, forRange: NSMakeRange(paragraphEnd, 0))
            if newParagraphStart < paragraphStart - 1 {
                newParagraphStart = paragraphStart
            }

			let paragraphRange = NSMakeRange(newParagraphStart, paragraphEnd - newParagraphStart)
			let limit = NSMaxRange(paragraphRange)
			var range = paragraphRange

			// Loop through the line until we reach the end
			while range.length > 0 && range.location < limit {
//                print(range)
//                print(s.substringWithRange(range))
//                if s.substringWithRange(range).containsString("class A < B") {
//                    print("There")
//                }
                let matches = matchPatterns(language.patterns, withString: string, inRange: range)
                var newLocation = limit
                if matches.results.count != 0 {
                    let newPlace = Int(applyResults(matches, callback: callback))
                    if newPlace != range.location {
                        newLocation = newPlace
                    }
                }
                if newLocation > limit {
                    paragraphEnd = newLocation
                    break
                }
                assert(range.length - (newLocation - range.location) >= 0)
				range.length = range.length - (newLocation - range.location)
                range.location = newLocation
			}
		}
	}


	// MARK: - Private
    
    private func matchPatterns(patterns: Patterns, withString string: String, inRange bounds: NSRange) -> ResultSet {
        var bestResult = ResultSet()
        for pattern in patterns.getContent() {
//            print("Pattern: \(pattern.name)")
            if let match = pattern.match {
                if let resultSet = matchExpression(match, withString: string, inRange: bounds, captures: pattern.captures, baseSelector: pattern.name) {
                    if !resultSet.isEmpty && resultSet.range!.length != 0 && bestResult.hasLowerPriorityThan(resultSet) {
                        bestResult = resultSet
                    }
                }
            } else if let begin = pattern.begin, end = pattern.end {
                guard let beginResults = matchExpression(begin, withString: string, inRange: bounds, captures: pattern.beginCaptures) else { continue }
                
                let beginRange = beginResults.range!
                var newLocation = NSMaxRange(beginRange)
                
                let s: NSString = string
                assert(s.length - newLocation >= 0)
                var endBounds = NSRange(location: newLocation, length: s.length - newLocation)
                
                var midResults = ResultSet()
                
                if pattern.subpatterns.getContent().count >= 1 {
                    let midTestResults = matchPatterns(pattern.subpatterns, withString: string, inRange: endBounds)
                    let midRange = midTestResults.range
                    if midRange != nil {
                        midResults.addResults(midTestResults)
                        newLocation = NSMaxRange(midRange!)
                        assert(endBounds.length - (newLocation - endBounds.location) >= 0)
                        endBounds = NSRange(location: newLocation, length: endBounds.length - (newLocation - endBounds.location))
                    }
                }
                
                let endResults = matchExpression(end, withString: string, inRange: endBounds, captures: pattern.endCaptures)
                if endResults == nil {
                    continue
                }
                let endRange = endResults!.range!
                
                var results = ResultSet()
                if let name = pattern.name {
                    results.addResult(Result(scope: name, range: NSUnionRange(beginRange, endRange)))
                }
                
                results.addResults(beginResults)
                results.addResults(midResults)
                results.addResults(endResults!)
                if bestResult.hasLowerPriorityThan(results) {
                    bestResult = results
                }
            } else if pattern.subpatterns.getContent().count >= 1 {
                var subPatternTry = matchPatterns(pattern.subpatterns, withString: string, inRange: bounds)
                if bestResult.hasLowerPriorityThan(subPatternTry) {
                    if pattern.name != nil && subPatternTry.range != nil {
                        subPatternTry.addResult(Result(scope: pattern.name!, range: subPatternTry.range!))
                    }
                    bestResult = subPatternTry
                }
            }
        }
        return bestResult
    }
    
	/// Matches a given regular expression in a String
    ///
    ///
    /// - returns: The resultset
	private func matchExpression(regularExpression: NSRegularExpression, withString string: String, inRange bounds: NSRange, captures: CaptureCollection?, baseSelector: String? = nil) -> ResultSet? {
		let matches = regularExpression.matchesInString(string, options: [], range: bounds)
        if matches.first == nil || matches.first!.range.location == NSNotFound {
            return nil
        }
        
        let result = matches.first!
        
		var resultSet = ResultSet()
        resultSet.addResult(Result(scope: baseSelector ?? "", range: result.range))

		if let captures = captures {
			for index in captures.captureIndexes {
				let range = result.rangeAtIndex(Int(index))
				if range.location == NSNotFound {
					continue
				}

				if let scope = captures[index]?.name {
					resultSet.addResult(Result(scope: scope, range: range))
				}
			}
		}

        return resultSet
	}

	private func applyResults(resultSet: ResultSet, callback: Callback) -> UInt {
		var i = 0
		for result in resultSet.results {
            if result.scope != "" && result.range.length > 0 {
                callback(scope: result.scope, range: result.range)
            }
			i = max(NSMaxRange(result.range), i)
		}
		return UInt(i)
	}
}
