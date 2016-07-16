//
//  AttributedParsingOperation.swift
//  SyntaxKit
//
//  Subclass of NSOperation that can be used for mutithreaded incremental
//  parsing with all the benefits of NSOperationQueue.
//
//  Created by Alexander Hedges on 17/04/16.
//  Copyright © 2016 Alexander Hedges. All rights reserved.
//

struct Diff {
    
    // MARK: - Properties
    
    var change: String
    var range: NSRange
    
    // MARK: - Operations
    
    /// - returns:  true if predicted change from diff matches the characters
    ///             from the new string in that range
    func representsChangesfromOldString(oldString: NSString, toNewString newStr: NSString) -> Bool {
        if self.range.length == 0 {
            if !Diff.stringChangeIsCompatible(newStr as String, isInsertion: true, changedRange: NSRange(location: self.range.location, length: (self.change as NSString).length), oldString: oldString) {
                return false
            }
            if newStr.substringWithRange(NSRange(location: self.range.location, length: (self.change as NSString).length)) != self.change {
                return false
            }
        } else {
            if !Diff.stringChangeIsCompatible(newStr as String, isInsertion: false, changedRange: self.range, oldString: oldString) {
                return false
            }
        }
        
        return true
    }
    
    /// - returns:  true if the number of characters changed is consistent with
    ///             the new string
    private static func stringChangeIsCompatible(newString: NSString, isInsertion insertion: Bool, changedRange range: NSRange, oldString: NSString) -> Bool {
        let oldLength = insertion ? newString.length - range.length : newString.length + range.length
        
        if oldString.length != oldLength {
            return false
        }
        return true
    }
}

public class AttributedParsingOperation: NSOperation {
    
    // MARK: - Types
    
    public typealias OperationCallback = [(range: NSRange, attributes: Attributes?)] -> Void
    
    
    // MARK: - Properties
    
    private let parser: AttributedParser
    private var stringToParse: String
    private var operationCallback: OperationCallback
    private var scopedStringResult: ScopedString
    
    private var range: NSRange?
    private var diff: Diff?
    
    
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
        let diff: Diff
        if insertion {
            diff = Diff(change: s.substringWithRange(range), range: NSRange(location: range.location, length: 0))
        } else {
            diff = Diff(change: "", range: range)
        }
        
        if diff.representsChangesfromOldString(previousOperation.scopedStringResult.underlyingString, toNewString: string) {
            self.diff = diff
            self.range = outdatedRangeForChangeInString(string, changeIsInsertion: insertion, changedRange: range, previousScopedString: scopedStringResult)
        }
    }
    
    
    // MARK: - NSOperation Implementation
    
    public override func main() {
        var resultsArray: [(range: NSRange, attributes: Attributes?)] = []
        parser.string = stringToParse
        
        var incrementalParsingInfo: (NSRange, Diff, ScopedString)?
        if range != nil && diff != nil {
            incrementalParsingInfo = (range: range!, diff: diff!, previousScopes: scopedStringResult)
        }
        
        let callback = { (_: String, range: NSRange, attributes: Attributes?) in
            if let attributes = attributes {
                resultsArray.append((range, attributes))
            }
        }
        
        if let result = parser.parse(incrementalParsingInfo, match: callback) {
            scopedStringResult = result
        }
        
        operationCallback(resultsArray)
        parser.string = ""
    }
    
    public override func cancel() {
        parser.aborted = true
        super.cancel()
    }
    
    
    // MARK: - Change Processing
    
    //  Implementation notes:
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
        if !Diff.stringChangeIsCompatible(newString, isInsertion: insertion, changedRange: range, oldString: previousScopes.underlyingString) {
            return nil
        }
        
        var potentialNewString = previousScopes
        
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
        
        let scopeAtIndex = potentialNewString.topmostScopeAtIndex(NSMaxRange(linesRange) - 1)
        if scopeAtIndex == potentialNewString.baseScope {
            return linesRange
        } else {
            let endOfCurrentScope = NSMaxRange(scopeAtIndex.range)
            return NSUnionRange(linesRange, NSRange(location: range.location, length: endOfCurrentScope - range.location))
        }
    }
}
