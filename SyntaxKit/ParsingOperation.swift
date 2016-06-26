//
//  AttributedParsingOperation.swift
//  SyntaxKit
//
//  Created by Alexander Hedges on 17/04/16.
//  Copyright © 2016 Alexander Hedges. All rights reserved.
//

import Foundation

public class AttributedParsingOperation: NSOperation {
    
    // MARK: - Types
    
    public typealias OperationCallback = [(range: NSRange, attributes: Attributes?)] -> Void
    
    
    // MARK: - Properties
    
    private let parser: AttributedParser
    private var stringToParse: String
    private var operationCallback: OperationCallback
    private var scopedStringResult: ScopedString
    
    private var range: NSRange?
    private var diff: (String?, NSRange)?
    
    
    // MARK: - Initializers
    
    public init(string: String, language: Language, theme: Theme, callback: OperationCallback) {
        stringToParse = string
        parser = AttributedParser(language: language, theme: theme)
        operationCallback = callback
        scopedStringResult = ScopedString(string: string)
        super.init()
    }
    
    public init(string: String, previousOperation: AttributedParsingOperation, changeIsInsertion insertion: Bool, changedRange range: NSRange, callback: OperationCallback) {
        stringToParse = string
        parser = previousOperation.parser
        parser.aborted = false
        operationCallback = callback
        scopedStringResult = previousOperation.scopedStringResult
        
        super.init()
        
        let s = string as NSString
        let diff: (String?, NSRange)
        if insertion {
            diff = (s.substringWithRange(range), NSRange(location: range.location, length: 0))
        } else {
            diff = (nil, range)
        }
        
        if diffRepresentsChanges(diff, fromOldString: previousOperation.scopedStringResult.underlyingString, toNewString: string) {
            self.diff = diff
            self.range = outdatedRangeForChangeInString(string, changeIsInsertion: insertion, changedRange: range, previousScopedString: scopedStringResult)
        }
    }
    
    
    // MARK: - NSOperation Implementation
    
    public override func main() {
        var resultsArray: [(range: NSRange, attributes: Attributes?)] = []
        parser.string = stringToParse
        parser.parse(inRange: range, withDiff: diff, usingPreviousScopesString: &scopedStringResult) { _, range, attributes in
            if let attributes = attributes {
                resultsArray.append((range, attributes))
            }
        }
        operationCallback(resultsArray)
        parser.string = ""
    }
    
    public override func cancel() {
        parser.aborted = true
        super.cancel()
    }
    
    // MARK: - Change Processing
    
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
    func outdatedRangeForChangeInString(newString: NSString, changeIsInsertion insertion: Bool, changedRange range: NSRange, previousScopedString previousScopes: ScopedString) -> NSRange? {
        if !stringChangeIsCompatible(newString, isInsertion: insertion, changedRange: range, oldString: previousScopes.underlyingString) {
            return nil
        }
        
        let potentialNewString = previousScopes.copy() as! ScopedString
        
        let linesRange: NSRange
        if insertion {
            potentialNewString.insertString(newString.substringWithRange(range), atIndex: range.location)
            linesRange = newString.lineRangeForRange(range)
        } else {
            potentialNewString.deleteCharactersInRange(range)
            linesRange = newString.lineRangeForRange(NSRange(location: range.location, length: 0))
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
    
    /// - returns:  true if diff not nil and predicted change from diff matches
    ///             the characters from the new string in that range
    func diffRepresentsChanges(diff: (String?, NSRange), fromOldString oldString: NSString, toNewString newStr: NSString) -> Bool {
        if diff.0 == nil {
            if !stringChangeIsCompatible(newStr as String, isInsertion: false, changedRange: diff.1, oldString: oldString) {
                return false
            }
        } else {
            if !stringChangeIsCompatible(newStr as String, isInsertion: true, changedRange: NSRange(location: diff.1.location, length: (diff.0! as NSString).length), oldString: oldString) {
                return false
            }
            if newStr.substringWithRange(NSRange(location: diff.1.location, length: (diff.0! as NSString).length)) != diff.0! {
                return false
            }
        }
        
        return true
    }
    
    /// - returns:  true if scopeString not nil and the number of characters
    ///             changed is consistent with the new string
    func stringChangeIsCompatible(newString: NSString, isInsertion insertion: Bool, changedRange range: NSRange, oldString: NSString) -> Bool {
        let oldLength = insertion ? newString.length - range.length : newString.length + range.length
        
        if oldString.length != oldLength {
            return false
        }
        return true
    }
}
