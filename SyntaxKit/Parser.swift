//
//  Parser.swift
//  SyntaxKit
//
//  This class is in charge of the painful task of recognizing the syntax patterns
//  Tries to match the output of TextMate as closely as possible.
//  Turns out TextMate doesn't highlight things it should highlight according to the
//  grammar so this is not entirely straight forward.
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
        let results = self.matchPatterns(language.patterns, withString: string, withEndPatternFromPattern: nil, startingAtIndex: 0)
        self.applyResults(results, callback: callback)
	}
    
    // MARK: - Private
    
    ///
    ///
    private func matchPatterns(patterns: Patterns, withString string: String, withEndPatternFromPattern endPattern: Pattern?, startingAtIndex startIndex: Int) -> ResultSet? {
        assert(endPattern == nil || endPattern!.end != nil)
        
        let s: NSString = string
        let length = s.length
        var paragraphStart = startIndex
        var paragraphEnd = startIndex
        var result: ResultSet?
        
        while paragraphEnd < length {
            s.getLineStart(nil, end: &paragraphEnd, contentsEnd: nil, forRange: NSMakeRange(paragraphEnd, 0))
            var range = NSRange(location: paragraphStart, length: paragraphEnd - paragraphStart)

            while range.length > 0 {
                let bestResultForMiddle = findBestPatternInPatterns(patterns, inString: string, inRange: range)
                
                if bestResultForMiddle != nil && !bestResultForMiddle!.isEmpty && bestResultForMiddle!.range.length != 0 {
                    if result == nil {
                        result = bestResultForMiddle
                    } else {
                        result!.addResults(bestResultForMiddle!)
                    }
                    let newStart = NSMaxRange(bestResultForMiddle!.range)
//                    if newStart > paragraphEnd {
//                        s.getParagraphStart(nil, end: &paragraphEnd, contentsEnd: nil, forRange: NSMakeRange(paragraphEnd, 0))
//                        range = NSRange(location: paragraphStart, length: paragraphEnd - paragraphStart)
//                        paragraphStart = newStart
//                    } else {
                        range = NSRange(location: newStart, length: max(0, range.length - (newStart - range.location)))
                        paragraphEnd = newStart
//                    }
                }
                
                if endPattern != nil {
                    var endMatchResult = self.matchExpression(endPattern!.end!, withString: string, inRange: range, captures: endPattern!.endCaptures)
                    if result != nil {
                        endMatchResult?.addResults(result!)
                    }
                    if endMatchResult != nil {
                        return endMatchResult
                    }
                }
                
                if bestResultForMiddle == nil || bestResultForMiddle!.isEmpty || bestResultForMiddle!.range.length == 0 {
                    range = NSRange(location: paragraphEnd, length: 0)
                }
            }
            paragraphStart = paragraphEnd++
        }
        
        if endPattern != nil { // failed to match end pattern
            return nil
        }
        return result
    }
    
    ///
    private func findBestPatternInPatterns(patterns: Patterns, inString string: String, inRange range: NSRange) -> ResultSet? {
        var bestResultForMiddle: ResultSet?
        for pattern in patterns.getContent() {
            let currRes = self.matchPattern(pattern, inString: string, inRange: range)
            if bestResultForMiddle == nil || bestResultForMiddle!.hasLowerPriorityThan(currRes) {
                bestResultForMiddle = currRes
            }
        }
        return bestResultForMiddle
    }
    
    ///
    private func matchPattern(pattern: Pattern, inString string: String, inRange bounds: NSRange) -> ResultSet? {
        if let match = pattern.match {
            if let resultSet = matchExpression(match, withString: string, inRange: bounds, captures: pattern.captures, baseSelector: pattern.name) {
                if resultSet.range.length != 0 {
                    return resultSet
                }
            }
        } else if let begin = pattern.begin, _ = pattern.end {
            guard let beginResults = matchExpression(begin, withString: string, inRange: bounds, captures: pattern.beginCaptures) else {
                return nil
            }
            
            let newLocation = NSMaxRange(beginResults.range)
            guard let endResults = matchPatterns(pattern.subpatterns, withString: string, withEndPatternFromPattern: pattern, startingAtIndex: newLocation) else {
                return nil
            }
            var result = ResultSet(startingRange: endResults.range)
            if pattern.name != nil {
                result.addResult(Result(scope: pattern.name!, range: NSUnionRange(beginResults.range, endResults.range)))
            }
            result.addResults(beginResults)
            result.addResults(endResults)
            return result
        } else if pattern.subpatterns.getContent().count >= 1 {
            var result = findBestPatternInPatterns(pattern.subpatterns, inString: string, inRange: bounds)
            if pattern.name != nil {
                result?.addResult(Result(scope: pattern.name!, range: result!.range))
            }
            return result
        }
        return nil
    }
    
	/// Matches a given regular expression in a String
    ///
    ///
    /// - returns: The set containing the results. May be nil if the expression could not match any part of the string. It may also be empty and only contain
	private func matchExpression(regularExpression: NSRegularExpression, withString string: String, inRange bounds: NSRange, captures: CaptureCollection?, baseSelector: String? = nil) -> ResultSet? {
		let matches = regularExpression.matchesInString(string, options: [.WithTransparentBounds], range: bounds)
        if matches.first == nil || matches.first!.range.location == NSNotFound {
            return nil
        }
        
        let result = matches.first!
        
		var resultSet = ResultSet(startingRange: result.range)
        if baseSelector != nil {
            resultSet.addResult(Result(scope: baseSelector!, range: result.range))
        }

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

	private func applyResults(resultSet: ResultSet?, callback: Callback) {
		for result in resultSet?.results ?? [] {
            if result.scope != "" && result.range.length > 0 {
                callback(scope: result.scope, range: result.range)
            }
		}
	}
}
