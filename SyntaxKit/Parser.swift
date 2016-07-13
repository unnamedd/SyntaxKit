//
//  Parser.swift
//  SyntaxKit
//
//  This class is in charge of the painful task of recognizing the syntax
//  patterns. It tries to match parsing behavior of TextMate as closely as 
//  possible.
//
//  The parsed string is stored as a property.
//
//  Created by Sam Soffes on 9/19/14.
//  Copyright © 2014-2015 Sam Soffes. All rights reserved.
//

public class Parser {
    
    // MARK: - Types
    
    public typealias Callback = (scope: String, range: NSRange) -> Void
    
    
    // MARK: - Properties
    
    public let language: Language
    
    var aborted = false
    
    var string: String
    
    
    // MARK: - Initializers
    
    public init(language: Language) {
        self.language = language
        self.string = ""
    }
    
    
    // MARK: - Public
    
    public func parse(string: String, match callback: Callback) {
        if aborted {
            return
        }
        self.string = string
        var scope = ScopedString(string: string)
        parse(inRange: nil, withDiff: nil, usingPreviousScopesString: &scope, match: callback)
        self.string = ""
    }
    
    
    // MARK: - Private
    
    //  Implementation notes:
    //  The first part tries to find the context in which parsing should take
    //  place (which block we are in), if any.
    //  The second part parses the string the until the full range is consumed
    //  and it may exceed that range if further parts of the string are outdated
    
    /// Parses the given string in the given range and calls the callback on
    /// every match of a scope
    ///
    /// If a range is treated more of a recommendation than a requirement.
    /// For best results supply a range that was returned from
    /// outdatedRangeForChangeInString called before calling this method.
    ///
    /// - parameter string:     The string that is parsed
    /// - parameter range:      The range in which the string should be parsed.
    ///                         On nil the entire string will be parsed.
    /// - parameter diff:       Addition: "Added string", (insertionIndex, 0)
    ///                         Deletion: nil, (deletionStart, deletionLength)
    /// - parameter scopes:     Denotes
    /// - parameter callback:   The callback to call on every match of a
    ///                         pattern identifier of the language
    /// - returns: A scopedString that contains the range results of the parsing
    ///             Or nil if the parsing was aborted.
    func parse(inRange range: NSRange?, withDiff diff: (String?, NSRange)?, inout usingPreviousScopesString scopes: ScopedString, match callback: Callback) {
        var endScope: Scope? = nil
        var bounds = range ?? NSRange(location: 0, length: (string as NSString).length)
        var scopesString = scopes
        if range != nil && diff != nil {
            endScope = scopesString.topLevelScopeAtIndex(bounds.location)
            if diff!.0 == nil {
                scopesString.deleteCharactersInRange(diff!.1)
            } else {
                scopesString.insertString(diff!.0!, atIndex: diff!.1.location)
            }
            if scopesString.underlyingString != string { // recover from inconsistecy (for instance "." shortcut)
                print("Used the emergency trick")
                bounds = NSRange(location: 0, length: (string as NSString).length)
                endScope = nil
                scopesString = ScopedString(string: string)
            }
        }
        
        var startIndex = bounds.location
        var endIndex = NSMaxRange(bounds)
        let allResults = ResultSet(startingRange: bounds)
        
        while startIndex < endIndex {
            let endPattern = endScope?.attribute as! Pattern?
            guard let results = self.matchPatterns(endPattern?.subpatterns ?? language.pattern.subpatterns, withEndPatternFromPattern: endPattern, startingAtIndex: startIndex, stopIndex: endIndex) else {
                return
            }
            
            if endScope != nil {
                allResults.addResult(Result(identifier: endScope!.patternIdentifier, range: results.range))
            }
            
            if results.range.length != 0 {
                allResults.addResults(results)
                startIndex = NSMaxRange(results.range)
                if endScope != nil {
                    endScope = scopesString.lowerScopeForScope(endScope!, AtIndex: startIndex)
                }
            } else {
                startIndex = endIndex
            }
            
            if startIndex > endIndex && scopesString.isInString(startIndex + 1) {
                let scopeAtIndex = scopesString.topLevelScopeAtIndex(startIndex + 1)
                if endScope == nil && scopesString.levelForScope(scopeAtIndex) > 0 ||
                    endScope != nil && scopesString.levelForScope(scopeAtIndex) > scopesString.levelForScope(endScope!) {
                    endIndex = NSMaxRange(scopeAtIndex.range)
                }
            }
        }
        scopesString.removeScopesInRange(allResults.range)
        scopes = scopesString
        if !aborted {
            self.applyResults(allResults, storingInScopesString: &scopesString, callback: callback)
        }
    }
    
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
    //  given range. This is intentional.
    
    /// Matches an array of patterns in the input
    ///
    /// - parameter patterns:       The patterns that should be matched
    /// - parameter string:         The string that should be matched against
    /// - parameter endPattern:     If specified, the pattern at which to stop
    ///                             the matching process, overrides stopIndex. 
    ///                             On nil it will match up to stopIndex.
    /// - parameter startingIndex:  The index at which to start matching
    /// - parameter stopIndex:      The index at which to stop matching
    ///
    /// - returns:  The result set containing the lexical scope names with range
    ///             information. May exceed stopIndex.
    ///             Only returns nil if the operation was aborted.
    private func matchPatterns(patterns: [Pattern], withEndPatternFromPattern endPattern: Pattern?, startingAtIndex startIndex: Int, stopIndex stop: Int) -> ResultSet? {
        assert(endPattern == nil || endPattern!.end != nil)
        
        assert((string as NSString).length >= stop)
        var lineStart = startIndex
        var lineEnd = startIndex
        let result = ResultSet(startingRange: NSRange(location: startIndex, length: 0))
        
        var bestMatchForMiddle: (pattern: Pattern, start: Int)?
        var endMatchResult: ResultSet?
        var resultForMiddle: ResultSet?
        var range: NSRange
        var newStart: Int
        
        while lineEnd < stop {
            (string as NSString).getLineStart(nil, end: &lineEnd, contentsEnd: nil, forRange: NSMakeRange(lineEnd, 0))
            range = NSRange(location: lineStart, length: lineEnd - lineStart)
            
            while range.length > 0 {
                if aborted {
                    return nil
                }
                
                bestMatchForMiddle = findBestPatternInPatterns(patterns, inRange: range)
                
                if endPattern != nil {
                    endMatchResult = self.matchExpression(endPattern!.end!, inRange: range, captures: endPattern!.endCaptures)
                    if endMatchResult != nil && (bestMatchForMiddle == nil || bestMatchForMiddle != nil &&
                        (!endPattern!.applyEndPatternLast && endMatchResult!.range.location <= bestMatchForMiddle!.start || endMatchResult!.range.location < bestMatchForMiddle!.start)) {
                        result.addResults(endMatchResult!)
                        return result
                    }
                }
                
                if bestMatchForMiddle != nil {
                    resultForMiddle = matchPattern(bestMatchForMiddle!.pattern, inRange: range)
                    if resultForMiddle == nil || resultForMiddle!.range.length == 0 {
                        break
                    }
                    result.addResults(resultForMiddle!)
                    newStart = NSMaxRange(resultForMiddle!.range)
                    range = NSRange(location: newStart, length: max(0, range.length - (newStart - range.location)))
                    lineEnd = max(lineEnd, newStart)
                } else {
                    break
                }
            }
            
            lineStart = lineEnd
        }
        
        result.extendWithRange(NSRange(location: startIndex, length: stop - startIndex))
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
    private func findBestPatternInPatterns(patterns: [Pattern], inRange bounds: NSRange) -> (pattern: Pattern, start: Int)? {
        var interestingBounds = bounds
        var bestResult: (pattern: Pattern, start: Int)?
        for pattern in patterns {
            let currentMatch = self.firstMatchOfPattern(pattern, inRange: bounds)
            if currentMatch?.start == bounds.location {
                return currentMatch
            } else if currentMatch != nil && (bestResult == nil || currentMatch != nil && currentMatch!.start < bestResult!.start) {
                bestResult = currentMatch
                interestingBounds.length = currentMatch!.start - interestingBounds.location
            }
        }
        return bestResult
    }
    
    private func firstMatchOfPattern(pattern: Pattern, inRange bounds: NSRange) -> (pattern: Pattern, start: Int)? {
        if let match = pattern.match {
            if let resultSet = matchExpression(match, inRange: bounds, captures: pattern.captures, baseSelector: pattern.name) {
                if resultSet.range.length != 0 {
                    return (pattern, resultSet.range.location)
                }
            }
        } else if let begin = pattern.begin {
            if let beginResults = matchExpression(begin, inRange: bounds, captures: pattern.beginCaptures) {
                return (pattern, beginResults.range.location)
            }
        } else if pattern.subpatterns.count >= 1 {
            return findBestPatternInPatterns(pattern.subpatterns, inRange: bounds)
        }
        return nil
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
    private func matchPattern(pattern: Pattern, inRange bounds: NSRange) -> ResultSet? {
        if let match = pattern.match {
            if let resultSet = matchExpression(match, inRange: bounds, captures: pattern.captures, baseSelector: pattern.name) {
                if resultSet.range.length != 0 {
                    return resultSet
                }
            }
        } else if let begin = pattern.begin, _ = pattern.end {
            guard let beginResults = matchExpression(begin, inRange: bounds, captures: pattern.beginCaptures) else {
                return nil
            }
            
            let newLocation = NSMaxRange(beginResults.range)
            guard let endResults = matchPatterns(pattern.subpatterns, withEndPatternFromPattern: pattern, startingAtIndex: newLocation, stopIndex: (string as NSString).length) else {
                return nil
            }
            
            let result = ResultSet(startingRange: endResults.range)
            if pattern.name != nil {
                result.addResult(Result(identifier: pattern.name!, range: NSUnionRange(beginResults.range, endResults.range)))
            }
            result.addResult(Scope(identifier: pattern.name ?? "", range: NSRange(location: beginResults.range.location + beginResults.range.length, length: NSUnionRange(beginResults.range, endResults.range).length - beginResults.range.length), attribute: pattern))
            result.addResults(beginResults)
            result.addResults(endResults)
            return result
        }
        return nil
    }
    
    /// Matches a given regular expression in a String and returns range
    /// information for the captures
    ///
    /// - parameter expression:     The regular expression to match
    /// - parameter string:         The string to match against
    /// - parameter range:          The range to which to restrict the match
    /// - parameter captures:       A collection of captures that can be used to
    ///                             add extra information to parts of the match.
    /// - parameter baseSelector:   String to associate with the entire range of
    ///                             the match
    ///
    /// - returns:  The set containing the results. May be nil if the expression
    ///             could not match any part of the string. It may also be empty
    ///             and only contain range information to show what it matched.
    private func matchExpression(regularExpression: NSRegularExpression, inRange bounds: NSRange, captures: CaptureCollection?, baseSelector: String? = nil) -> ResultSet? {
        guard let result = regularExpression.matchesInString(string, options: [.WithTransparentBounds], range: bounds).first else {
            return nil
        }
        
        let resultSet = ResultSet(startingRange: result.range)
        if baseSelector != nil {
            resultSet.addResult(Result(identifier: baseSelector!, range: result.range))
        }
        
        if let captures = captures {
            for index in captures.captureIndexes {
                if result.numberOfRanges <= Int(index) {
                    print("Attention unexpected capture (\(index) to \(result.numberOfRanges)): \(regularExpression.pattern)")
                    continue
                }
                let range = result.rangeAtIndex(Int(index))
                if range.location == NSNotFound {
                    continue
                }
                
                if let scope = captures[index]?.name {
                    resultSet.addResult(Result(identifier: scope, range: range))
                }
            }
        }
        
        return resultSet
    }
    
    //  Implementation note:
    //  In this project the difference between a Result and a Scope is that
    //  the scope has the attribute set while the Result does not.
    
    /// Uses the callback to communicate the result of the parsing pass back
    /// to the caller of parse.
    ///
    /// - parameter results:        The results of the parsing pass
    /// - parameter scopesString:   The place to store the scopes
    /// - parameter callback:       The method to call on every successful match
    private func applyResults(results: ResultSet, inout storingInScopesString scopesString: ScopedString, callback: Callback) {
        callback(scope: Language.globalScope, range: results.range)
        for result in results.results where result.range.length > 0 {
            if result.attribute != nil {
                scopesString.addScopeAtBottom(result as Scope)
            } else if result.patternIdentifier != "" {
                callback(scope: result.patternIdentifier, range: result.range)
            }
        }
    }
}
