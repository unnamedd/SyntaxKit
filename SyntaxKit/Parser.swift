//
//  Parser.swift
//  SyntaxKit
//
//  This class is in charge of the painful task of recognizing the syntax 
//  patterns. It tries to match the output of TextMate as closely as possible.
//  Turns out TextMate doesn't highlight things it should highlight according to
//  the grammar so this is not entirely straight forward.
//
//  Created by Sam Soffes on 9/19/14. Edited by Alexander Hedges
//  Copyright © 2014-2015 Sam Soffes. All rights reserved.
//

import Foundation

public class Parser {

	// MARK: - Types

	public typealias Callback = (scope: String, range: NSRange) -> Void


	// MARK: - Properties

	public let language: Language
    
//    private var scopesString: NSMutableAttributedString?

	// MARK: - Initializers

	public init(language: Language) {
		self.language = language
	}


	// MARK: - Parsing
    
//    public func rangeToParseInString(string: String, changeAtLocation location: Int) -> NSRange {
//        return NSRange(location: 0, length: (string as NSString).length)
//    }

	public func parse(string: String, match callback: Callback) {
        let results = self.matchPatterns(language.patterns, withString: string, withEndPatternFromPattern: nil, startingAtIndex: 0)
        self.applyResults(results, callback: callback)
	}
    
    // MARK: - Private
    
    //  Algorithmic notes:
    //  A pattern expression can not match a substring spanning multiple lines
    //  so in the outer loop the string is decomposed into its lines.
    //  In the inner loop it tries to repeatedly match a pattern followed by the
    //  end pattern until either the line is consumed or it has found the end.
    //  This procedure is repeated with the subsequent lines until it has either
    //  matched the end pattern or the string is consumed entirely.
    //  If it can find neither in a line it moves to the next one.
    
    //  Implementation note:
    //  The matching of the middle part may return a match that goes beyond the
    //  given range. this is intentional
    
    /// Matches an array of patterns in the input
    /// 
    /// - parameter patterns:       The patterns to match the sting against
    /// - parameter string:         The matched string
    /// - parameter endPattern:     If specified, the pattern at which to stop
    ///                             the matching process. Otherwise it will just
    ///                             match the entire string.
    /// - parameter startingIndex:  The index at which to start matching
    ///
    /// - returns:  The result set containing the lexical scope names with range
    ///             information or nil of nothing could be found.
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
                    range = NSRange(location: newStart, length: max(0, range.length - (newStart - range.location)))
                    paragraphEnd = newStart
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
    
    /// Helper method that iterates over the given patterns and tries to match
    /// them in order.
    ///
    /// It returns the best match, if many are possible. Which is the result
    /// that starts the soonest and is encountered first.
    ///
    /// - parameter patterns:   The patterns that should be matched
    /// - parameter string:     The string that should be matched against
    /// - parameter range:      The range in which the matching should happen.
    ///                         Though it is not guaranteed that the length of 
    ///                         the result does not exceed the length of the 
    ///                         range.
    ///
    /// - returns:  The results. nil if nothing could be matched and an empty
    ///             set if something could be matched but it doesn't have any
    ///             information associated with the match.
    private func findBestPatternInPatterns(patterns: Patterns, inString string: String, inRange range: NSRange) -> ResultSet? {
        var bestResultForMiddle: ResultSet?
        for pattern in patterns.getContent() {
            let currRes = self.matchPattern(pattern, inString: string, inRange: range)
            if currRes?.range.location == range.location {
                return currRes
            } else if bestResultForMiddle == nil || currRes != nil && currRes!.range.location < bestResultForMiddle!.range.location {
                bestResultForMiddle = currRes
            }
        }
        return bestResultForMiddle
    }
    
    //  Implementation note:
    //  The order in which the beginning middle and end are added to the final
    //  result matters.
    
    /// Matches a single pattern in the string in the given range
    ///
    /// A pattern may be one three options:
    /// * A single pattern called match which should be matched
    /// * A begin and an end pattern containing an optional body of patterns 
    ///     which should be matched between the begin and the end
    /// * Only a body of patterns without the begin and end. Any pattern may be 
    ///     matched successfully
    ///
    /// - returns: The result of the match. Nil if unsuccessful
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
    
	/// Matches a given regular expression in a String and returns range 
    /// information for the captures
    ///
    /// - parameter expression: The regular expression to match
    /// - parameter string:     The string to match against
    /// - parameter range:      The range to which to restrict the match
    /// - parameter captures:   A collection of captures that can be used to add
    ///                         extra information to parts of the match.
    /// - parameter baseSelector:   String to associate with the entire range of
    ///                             the match
    ///
    /// - returns:  The set containing the results. May be nil if the expression
    ///             could not match any part of the string. It may also be empty
    ///             and only contain range information to show what it matched.
	private func matchExpression(regularExpression: NSRegularExpression, withString string: String, inRange bounds: NSRange, captures: CaptureCollection?, baseSelector: String? = nil) -> ResultSet? {
        guard let result = regularExpression.matchesInString(string, options: [.WithTransparentBounds], range: bounds).first else {
            return nil
        }
        
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
