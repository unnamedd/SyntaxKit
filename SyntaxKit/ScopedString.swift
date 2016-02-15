//
//  ScopedString.swift
//  SyntaxKit
//
//  A datastructure that facilitates working with strings that have nested 
//  scopes associated with them. A scope being a named range that can have an 
//  attribute assciated with it for the callers convenience.
//  The ranges can be nested. The datastrucuture could be visualized like this:
//  
//  Top:                              ----
//                              -------------
//            -------   -----------------------------
//  Bottom:  ------------------------------------------
//  String: "(This is) (string (with (nest)ed) scopes)!"
//  
//  Note:
//  The bottom-most layer is implicit and is not stored.
//  If no layer can hold the inserted scope without intersections a new layer is
//  added.
//
//  The datastructure might be optimized with binary search for insertions at 
//  the individual levels.
//
//  Created by Alexander Hedges on 29/01/16.
//  Copyright © 2016 Alexander Hedges. All rights reserved.
//

import Foundation

extension NSRange {
    
    func isEmpty() -> Bool {
        return length == 0
    }
    
    func containsIndex(index: Int) -> Bool {
        return index >= location && index <= location + length
    }
    
    mutating func subtractRange(range: NSRange) {
        length -= NSIntersectionRange(range, NSRange(location: location, length: length)).length
        if (range.location < self.location) {
            self.location -= NSIntersectionRange(range, NSRange(location: 0, length: self.location)).length
        }
    }
    
    mutating func insertRange(range: NSRange) {
        if self.containsIndex(range.location) && range.location < NSMaxRange(self) {
            length += range.length
        } else if location > range.location {
            location += range.length
        }
    }
}

class ScopedString: NSObject, NSCopying {
    
    // MARK: - Properties
    
    var underlyingString: String
    
    private var levels: [[Scope]] = []
    
    var baseScope: Scope {
        return Scope(identifier: "BaseNameString", range: NSRange(location: 0, length: (underlyingString as NSString).length), attribute: nil)
    }
    
    
    // MARK: - Initializers
    
    init(string: String) {
        self.underlyingString = string
    }
    
    
    // MARK: - Interface
    
    func copyWithZone(zone: NSZone) -> AnyObject {
        let newScopedString = ScopedString(string: self.underlyingString)
        newScopedString.levels = []
        for level in levels {
            var newLevel: [Scope] = []
            for scope in level {
                let newScope = Scope(identifier: scope.patternIdentifier, range: scope.range, attribute: scope.attribute)
                newLevel.append(newScope)
            }
            newScopedString.levels.append(newLevel)
        }
        return newScopedString
    }
    
    func numberOfScopes() -> Int {
        var sum = 1
        for level in levels {
            sum += level.count
        }
        return sum
    }
    
    func numberOfLevels() -> Int {
        return levels.count + 1
    }
    
    func isInString(index: Int) -> Bool {
        return index >= 0 && index <= baseScope.range.length
    }
    
    func addScopeAtTop(scope: Scope) {
        assert(NSIntersectionRange(scope.range, baseScope.range).length == scope.range.length)
        
        var added = false
        for level in 0..<levels.count {
            if findScopeIntersectionWithRange(scope.range, atLevel: levels[level]) == nil {
                levels[level].insert(scope, atIndex: self.insertionPointForRange(scope.range, atLevel: levels[level]))
                added = true
                break
            }
        }
        if !added {
            levels.append([scope])
        }
    }
    
    func addScopeAtBottom(scope: Scope) {
        assert(NSIntersectionRange(scope.range, baseScope.range).length == scope.range.length)
        
        var added = false
        for var level = levels.count - 1; level >= 0; level-- {
            if findScopeIntersectionWithRange(scope.range, atLevel: levels[level]) == nil {
                levels[level].insert(scope, atIndex: self.insertionPointForRange(scope.range, atLevel: levels[level]))
                added = true
                break
            }
        }
        if !added {
            levels.insert([scope], atIndex: 0)
        }
    }
    
    func topLevelScopeAtIndex(index: Int) -> Scope {
        let indexRange = NSRange(location: index, length: 1)
        for var i = levels.count - 1; i >= 0; i-- {
            let level = levels[i]
            if let theScope = findScopeIntersectionWithRange(indexRange, atLevel: level) {
                return theScope
            }
        }
        return baseScope
    }
    
    func lowerScopeForScope(scope: Scope, AtIndex index: Int) -> Scope {
        assert(index >= 0 && index <= baseScope.range.length)
        
        var foundScope = false
        let indexRange = NSRange(location: index, length: 1)
        for var i = levels.count - 1; i >= 0; i-- {
            let level = levels[i]
            let theScope = findScopeIntersectionWithRange(indexRange, atLevel: level)
            if theScope != nil {
                if foundScope {
                    return scope
                } else if theScope! == scope {
                    foundScope = true
                }
            }
        }
        return baseScope
    }
    
    func levelForScope(scope: Scope) -> Int {
        for var i = 0; i < levels.count; i++ {
            let level = levels[i]
            for currentScope in level {
                if scope == currentScope {
                    return i + 1
                }
            }
        }
        if scope == baseScope {
            return 0
        }
        return -1
    }
    
    func removeScopesInRange(range: NSRange) {
        assert(NSIntersectionRange(range, baseScope.range).length == range.length)
        
        for var level = levels.count-1; level >= 0; level-- {
            for var scope = levels[level].count-1; scope >= 0; scope-- {
                let theScope = levels[level][scope]
                if NSIntersectionRange(theScope.range, range).length == theScope.range.length {
                    levels[level].removeAtIndex(scope)
                }
            }
            if levels[level].count == 0 {
                levels.removeAtIndex(level)
            }
        }
    }
    
    func insertString(string: String, atIndex index: Int) {
        assert(index >= 0 && index <= baseScope.range.length)
        
        let s = underlyingString as NSString
        let length = (string as NSString).length
        let mutableString = s.mutableCopy() as! NSMutableString
        mutableString.insertString(string, atIndex: index)
        self.underlyingString = mutableString.copy() as! String
        for level in 0..<levels.count {
            for scope in 0..<levels[level].count {
                levels[level][scope].range.insertRange(NSRange(location: index, length: length))
            }
        }
    }
    
    func deleteCharactersInRange(range: NSRange) {
        assert(NSIntersectionRange(range, baseScope.range).length == range.length)
        
        let mutableString = (self.underlyingString as NSString).mutableCopy() as! NSMutableString
        mutableString.deleteCharactersInRange(range)
        self.underlyingString = mutableString.copy() as! String
        for var level = levels.count-1; level >= 0; level-- {
            for var scope = levels[level].count-1; scope >= 0 ; scope-- {
                var theRange = levels[level][scope].range
                theRange.subtractRange(range)
                if theRange.isEmpty() {
                    levels[level].removeAtIndex(scope)
                } else {
                    levels[level][scope].range = theRange
                }
            }
            if levels[level].count == 0 {
                levels.removeAtIndex(level)
            }
        }
    }
    
    
    // MARK: - Private
    
    private func findScopeIntersectionWithRange(range: NSRange, atLevel level: [Scope]) -> Scope? {
        for scope in level {
            if NSIntersectionRange(scope.range, range).length != 0 {
                return scope
            }
        }
        return nil
    }
    
    private func insertionPointForRange(range: NSRange, atLevel level: [Scope]) -> Int {
        var i = 0
        for scope in level {
            if range.location < scope.range.location {
                return i
            }
            i++
        }
        return i
    }
}
