//
//  Parser.swift
//  SyntaxKit
//
//  This class is in charge of the painful task of recognizing the syntax
//  patterns. It tries to match the output of TextMate as closely as possible.
//  Turns out TextMate doesn't highlight things it should highlight according to
//  the grammar so this is not entirely straight forward.
//
//  It supports incremental parsing. The recommmend usage is to ask the class
//  for the range it should be reparsed on the given change. This range can then 
//  be passed to parsed.
//
//  Created by Sam Soffes on 9/19/14. Edited by Alexander Hedges
//  Copyright © 2014-2015 Sam Soffes. Copyright (C) 2016 Alexander Hedges.
//  All rights reserved.
//

import Foundation

public class Parser {
    
    // MARK: - Types
    
    public typealias Callback = (scope: String, range: NSRange) -> Void
    
    
    // MARK: - Properties
    
    public let language: Language
    
    //  Contains the string previously passed to parse() if parse has already
    //  been called. It stores all the associated scopes with hierarchical 
    //  information and ranges. The attributes of the scopes are values of type 
    //  Pattern, the begin/end pattern associated with the scope. The scopes
    //  might not be fully populated after a call to parse with a limited range.
    private var scopesString: ScopedString?
    
    //  Contains information on the previously generated outdated range. This
    //  property is invalidated after every call to parse. The diff stores
    //  information on the change that was analysed in outdateRange and is used
    //  in parse. 
    //  If the inspected change is an addition the string is set to the 
    //  potentially inserted string and the range is set to 
    //  (insertion, length: 0).
    //  If the inspected change is a deletion the string is nil and the range is
    //  the range that would potentially be deleted.
    private var diff: (String?, NSRange)?
    
    
    // MARK: - Initializers
    
    public init(language: Language) {
        self.language = language
    }
    
    
    // MARK: - Public
    
    //  Algorithmic notes:
    //  If change occurred in a block reparse the lines in which the change
    //  happened and the range of the block from this point on. If the change
    //  occurred in the global scope just reparse the lines that changed.
    
    /// Returns the range in the given string that should be re-parsed after the
    /// given change.
    ///
    /// This method returns a range that can be safely passed into parse so that
    /// only a part of the string has to be reparsed.
    /// In fact passing anything other than this range to parse might lead to 
    /// uninteded results but is not prohibited.
    /// This method is only guaranteed to possibly not return nil if parse was 
    /// called on the old string before this call. The only kinds of changed 
    /// supported are single insertions and deletions of strings.
    ///
    /// - parameter newString:  The examined new string. Should be the product 
    ///                         of previously parsed + change.
    /// - parameter insertion:  If the change applied to the old value is an 
    ///                         insertion as opposed to a deletion.
    /// - parameter range:      The range in which the change occurred. In case
    ///                         of an insertion the range in the new string that
    ///                         was inserted. For a deletion it is the range in 
    ///                         the old string that was deleted.
    ///
    /// - returns:  A range in newString that can be safely re-parsed. Or nil if
    ///             everything has to be reparsed.
    public func outdatedRangeForChangeInString(newString: String, changeIsInsertion insertion: Bool, changedRange range: NSRange) -> NSRange? {
        if !stringChangeIsCompatible(newString, isInsertion: insertion, changedRange: range) {
            return nil
        }
        
        let potentialNewString = scopesString!.copy() as! ScopedString
        
        let s = newString as NSString
        let linesRange: NSRange
        if insertion {
            potentialNewString.insertString(s.substringWithRange(range), atIndex: range.location)
            diff = (s.substringWithRange(range), NSRange(location: range.location, length: 0))
            linesRange = s.lineRangeForRange(range)
        } else {
            potentialNewString.deleteCharactersInRange(range)
            diff = (nil, range)
            linesRange = s.lineRangeForRange(NSRange(location: range.location, length: 0))
        }
        if potentialNewString.underlyingString != newString {
            return nil
        }
        
        let scopeAtIndex = potentialNewString.topLevelScopeAtIndex(NSMaxRange(linesRange) - 1)
        if scopeAtIndex == potentialNewString.baseScope {
            return linesRange
        } else {
            let endOfCurrentScope = NSMaxRange(scopeAtIndex.range)
            return NSUnionRange(linesRange, NSRange(location: range.location, length: endOfCurrentScope - range.location))
        }
    }
    
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
    /// - parameter callback:   The callback to call on every match of a
    ///                         pattern identifier of the language
    public func parse(string: String, inRange range: NSRange? = nil, match callback: Callback) {
        var endScope: Scope? = nil
        var bounds = range
        if bounds == nil {
            bounds = NSRange(location: 0, length: (string as NSString).length)
            scopesString = ScopedString(string: string)
        } else if diffRepresentsChangesFromOldStringToNewString(string) {
            endScope = self.scopesString!.topLevelScopeAtIndex(bounds!.location)
            if diff!.0 == nil {
                scopesString!.deleteCharactersInRange(diff!.1)
            } else {
                scopesString!.insertString(diff!.0!, atIndex: diff!.1.location)
            }
            if scopesString!.underlyingString != string { // recover from inconsistecy (for instance "." shortcut)
                print("Used the emergency trick")
                bounds = NSRange(location: 0, length: (string as NSString).length)
                endScope = nil
                scopesString = ScopedString(string: string)
            }
        } else {
            // here we don't guarantee best results, the user passed in a range we didn't give him
            scopesString = ScopedString(string: string)
            print("Warning: No guarantee for optimal results")
        }
        
        var startIndex = bounds!.location
        var endIndex = NSMaxRange(bounds!)
        var allResults = ResultSet(startingRange: bounds!)
        
        while startIndex < endIndex {
            let endPattern = endScope?.attribute as! Pattern?
            let results = self.matchPatterns(endPattern?.subpatterns ?? language.pattern.subpatterns, withString: string, withEndPatternFromPattern: endPattern, startingAtIndex: startIndex, stopIndex: endIndex)
            
            if endScope != nil {
                allResults.addResult(Result(identifier: endScope!.patternIdentifier, range: results.range))
            }
            
            if results.range.length != 0 {
                allResults.addResults(results)
                startIndex = NSMaxRange(results.range)
                if endScope != nil {
                    endScope = self.scopesString!.lowerScopeForScope(endScope!, AtIndex: startIndex)
                }
            } else {
                startIndex = endIndex
            }
            
            if startIndex > endIndex && scopesString!.isInString(startIndex + 1) {
                let scopeAtIndex = scopesString!.topLevelScopeAtIndex(startIndex + 1)
                if endScope == nil && scopesString!.levelForScope(scopeAtIndex) > 0 ||
                    endScope != nil && scopesString!.levelForScope(scopeAtIndex) > scopesString!.levelForScope(endScope!) {
                    endIndex = NSMaxRange(scopeAtIndex.range)
                }
            }
        }
        scopesString!.removeScopesInRange(allResults.range)
        self.applyResults(allResults, callback: callback)
        diff = nil
    }
    
    
    // MARK: - Private
    
    // MARK: Range Helpers
    
    /// - returns:  true if scopeString not nil and the number of characters
    ///             changed is consistent with the new string
    private func stringChangeIsCompatible(newString: NSString, isInsertion insertion: Bool, changedRange range: NSRange) -> Bool {
        if scopesString == nil {
            return false
        }
        
        var oldLength = newString.length
        if insertion {
            oldLength -= range.length
        } else {
            oldLength += range.length
        }
        
        if (scopesString!.underlyingString as NSString).length != oldLength {
            print("Warning: incompatible change")
            return false
        }
        return true
    }
    
    /// - returns:  true if diff not nil and predicted change from diff matches
    ///             the characters from the new string in that range
    private func diffRepresentsChangesFromOldStringToNewString(newStr: NSString) -> Bool {
        if diff == nil {
            print("Warning: Diff is nil")
            return false
        }
        if diff!.0 == nil {
            if !stringChangeIsCompatible(newStr as String, isInsertion: false, changedRange: diff!.1) {
                return false
            }
        } else {
            if !stringChangeIsCompatible(newStr as String, isInsertion: true, changedRange: NSRange(location: diff!.1.location, length: (diff!.0! as NSString).length)) {
                return false
            }
            if newStr.substringWithRange(NSRange(location: diff!.1.location, length: (diff!.0! as NSString).length)) != diff!.0! {
                print("Warning: Passed in a wierd string")
                return false
            }
        }
        
        return true
    }
        
    // MARK: Parsing
    
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
    private func matchPatterns(patterns: [Pattern], withString string: String, withEndPatternFromPattern endPattern: Pattern?, startingAtIndex startIndex: Int, stopIndex stop: Int) -> ResultSet {
        assert(endPattern == nil || endPattern!.end != nil)
        
        let s: NSString = string
        assert(s.length >= stop)
        var lineStart = startIndex
        var lineEnd = startIndex
        var result = ResultSet(startingRange: NSRange(location: startIndex, length: 0))
        
        while lineEnd < stop {
            s.getLineStart(nil, end: &lineEnd, contentsEnd: nil, forRange: NSMakeRange(lineEnd, 0))
            var range = NSRange(location: lineStart, length: lineEnd - lineStart)
            
            while range.length > 0 {
                let bestResultForMiddle = findBestPatternInPatterns(patterns, inString: string, inRange: range)
                
                if endPattern != nil {
                    let endMatchResult = self.matchExpression(endPattern!.end!, withString: string, inRange: range, captures: endPattern!.endCaptures)
                    if endMatchResult != nil && (bestResultForMiddle == nil || endMatchResult!.range.location < bestResultForMiddle!.range.location) {
                        result.addResults(endMatchResult!)
                        return result
                    }
                }
                
                if bestResultForMiddle != nil && bestResultForMiddle!.range.length != 0 {
                    result.addResults(bestResultForMiddle!)
                    let newStart = NSMaxRange(bestResultForMiddle!.range)
                    range = NSRange(location: newStart, length: max(0, range.length - (newStart - range.location)))
                    lineEnd = max(lineEnd, newStart)
                } else {
                    break
                }
            }
            
            lineStart = lineEnd
            lineEnd += 1
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
    private func findBestPatternInPatterns(patterns: [Pattern], inString string: String, inRange bounds: NSRange) -> ResultSet? {
        var bestResultForMiddle: ResultSet?
        for pattern in patterns {
            let currRes = self.matchPattern(pattern, inString: string, inRange: bounds)
            if currRes?.range.location == bounds.location {
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
            let endResults = matchPatterns(pattern.subpatterns, withString: string, withEndPatternFromPattern: pattern, startingAtIndex: newLocation, stopIndex: (string as NSString).length)
            var result = ResultSet(startingRange: endResults.range)
            if pattern.name != nil {
                result.addResult(Result(identifier: pattern.name!, range: NSUnionRange(beginResults.range, endResults.range)))
            }
            result.addResult(Scope(identifier: pattern.name ?? "", range: NSRange(location: beginResults.range.location + beginResults.range.length, length: result.range.length - beginResults.range.length), attribute: pattern))
            result.addResults(beginResults)
            result.addResults(endResults)
            return result
        } else if pattern.subpatterns.count >= 1 {
            var result = findBestPatternInPatterns(pattern.subpatterns, inString: string, inRange: bounds)
            if pattern.name != nil {
                result?.addResult(Result(identifier: pattern.name!, range: result!.range))
            }
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
    private func matchExpression(regularExpression: NSRegularExpression, withString string: String, inRange bounds: NSRange, captures: CaptureCollection?, baseSelector: String? = nil) -> ResultSet? {
        guard let result = regularExpression.matchesInString(string, options: [.WithTransparentBounds], range: bounds).first else {
            return nil
        }
        
        var resultSet = ResultSet(startingRange: result.range)
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
    /// - parameter resultSet:  The results of the parsing pass
    /// - parameter callback:   The method to call on every successful match
    private func applyResults(resultSet: ResultSet?, callback: Callback) {
        guard let results = resultSet else {
            return
        }
        
        callback(scope: Language.globalScope, range: results.range)
        for result in results.results where result.range.length > 0 {
            if result.attribute != nil {
                self.scopesString?.addScopeAtBottom(result as Scope)
            } else if result.patternIdentifier != "" {
                callback(scope: result.patternIdentifier, range: result.range)
            }
        }
    }
}
