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
//  The bottom-most layer is implicit and is not stored. Unlike shown above the
//  ranges of the scopesare actually headed.
//  If no layer can actually hold the inserted scope a new layer is added.
//
//  The datastructure might be optimized with binary search for insertions at 
//  the individual levels.
//
//  Created by Alexander Hedges on 29/01/16.
//  Copyright © 2016 Sam Soffes. All rights reserved.
//

import Foundation

/// A range divided into a head and body part
struct HeadedRange: Equatable {
    var location: Int
    var headerLength: Int
    var bodyLength: Int
    
    var entireRange: NSRange {
        return NSRange(location: location, length: headerLength + bodyLength)
    }
    
    var bodyRange: NSRange {
        return NSRange(location: location + headerLength, length: bodyLength)
    }
    
    func isEmpty() -> Bool {
        return  headerLength == 0 && bodyLength == 0
    }
    
    func isInBody(index: Int) -> Bool {
        return index >= location + headerLength && index <= location + headerLength + bodyLength
    }
    
    func isInHeader(index: Int) -> Bool {
        return index >= location && index <= location + headerLength
    }
    
    mutating func subtractRange(range: NSRange) {
        bodyLength -= max(0, NSIntersectionRange(range, NSRange(location: location + headerLength, length: bodyLength)).length)
        headerLength -= max(0, NSIntersectionRange(range, NSRange(location: location, length: headerLength)).length)
    }
    
    mutating func insertRange(range: NSRange) {
        if isInBody(range.location) {
            bodyLength += range.length
        } else if isInHeader(range.location) {
            headerLength += range.length
        }
    }
}

func ==(lhs: HeadedRange, rhs: HeadedRange) -> Bool {
    return lhs.location == rhs.location && lhs.headerLength == rhs.headerLength && lhs.bodyLength == rhs.bodyLength
}


/// A scope of a
struct Scope: Equatable {
    var name: String
    var range: HeadedRange
    var attribute: AnyObject?
}

func ==(lhs: Scope, rhs: Scope) -> Bool {
    return lhs.name == rhs.name && lhs.range == rhs.range
}


class ScopedString: NSObject, NSCopying {
    
    var underlyingString: String
    
    private var levels: [[Scope]] = []
    
    var baseScope: Scope {
        return Scope(name: "BaseNameString", range: HeadedRange(location: 0, headerLength: 0, bodyLength: (underlyingString as NSString).length), attribute: nil)
    }
    
    init(string: String) {
        self.underlyingString = string
    }
    
    func copyWithZone(zone: NSZone) -> AnyObject {
        let newScopedString = ScopedString(string: self.underlyingString)
        newScopedString.levels = self.levels
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
    
    func addScopeAtTopWithName(name: String, inRange range: HeadedRange, withAttribute attribute: AnyObject? = nil) {
        assert(NSIntersectionRange(range.entireRange, baseScope.range.entireRange).length == range.entireRange.length)
        
        let newScope = Scope(name: name, range: range, attribute: attribute)
        var added = false
        for level in 0..<levels.count {
            if findScopeIntersectionWithRange(range.entireRange, atLevel: levels[level]) == nil {
                levels[level].insert(newScope, atIndex: self.insertionPointForRange(range.entireRange, atLevel: levels[level]))
                added = true
                break
            }
        }
        if !added {
            levels.append([newScope])
        }
    }
    
    func addScopeAtBottomWithName(name: String, inRange range: HeadedRange, withAttribute attribute: AnyObject? = nil) {
        assert(NSIntersectionRange(range.entireRange, baseScope.range.entireRange).length == range.entireRange.length)
        
        let newScope = Scope(name: name, range: range, attribute: attribute)
        var added = false
        for var level = levels.count - 1; level >= 0; level-- {
            if findScopeIntersectionWithRange(range.entireRange, atLevel: levels[level]) == nil {
                levels[level].insert(newScope, atIndex: self.insertionPointForRange(range.entireRange, atLevel: levels[level]))
                added = true
                break
            }
        }
        if !added {
            levels.insert([newScope], atIndex: 0)
        }
    }
    
    func topLevelScopeAtIndex(index: Int, onlyBodyResults body: Bool) -> Scope {
        assert(index >= 0 && index < baseScope.range.entireRange.length)
        
        let indexRange = NSRange(location: index, length: 1)
        for var i = levels.count - 1; i >= 0; i-- {
            let level = levels[i]
            let theScope = findScopeIntersectionWithRange(indexRange, atLevel: level)
            if theScope != nil {
                if !body || NSIntersectionRange(theScope!.range.bodyRange, indexRange).length != 0 {
                    return theScope!
                }
            }
        }
        return baseScope
    }
    
    func lowerScopeForScope(scope: Scope, AtIndex index: Int) -> Scope {
        assert(index >= 0 && index < baseScope.range.entireRange.length)
        
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
    
    func removeScopesInRange(range: NSRange) {
        assert(NSIntersectionRange(range, baseScope.range.entireRange).length == range.length)
        
        for var level = levels.count-1; level >= 0; level-- {
            for var scope = levels[level].count-1; scope >= 0; scope-- {
                let theScope = levels[level][scope]
                if NSIntersectionRange(theScope.range.entireRange, range).length == theScope.range.entireRange.length {
                    levels[level].removeAtIndex(scope)
                }
            }
            if levels[level].count == 0 {
                levels.removeAtIndex(level)
            }
        }
    }
    
    func insertString(string: String, atIndex index: Int) {
        assert(index >= 0 && index < baseScope.range.entireRange.length)
        
        let s = underlyingString as NSString
        let length = (string as NSString).length
        let indexRange = NSRange(location: index, length: 1)
        let mutableString = s.mutableCopy() as! NSMutableString
        mutableString.insertString(string, atIndex: index)
        self.underlyingString = mutableString.copy() as! String
        for level in 0..<levels.count {
            for scope in 0..<levels[level].count {
                var newScope = levels[level][scope]
                if NSIntersectionRange(newScope.range.entireRange, indexRange).length != 0 {
                    newScope.range.insertRange(NSRange(location: index, length: length))
                } else if newScope.range.location > index {
                    newScope.range.location += length
                }
                levels[level][scope] = newScope
            }
        }
    }
    
    func deleteCharactersInRange(range: NSRange) {
        assert(NSIntersectionRange(range, baseScope.range.entireRange).length == range.length)
        
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
            if NSIntersectionRange(scope.range.entireRange, range).length != 0 {
                return scope
            }
        }
        return nil
    }
    
    private func insertionPointForRange(range: NSRange, atLevel level: [Scope]) -> Int {
        var i = 0
        for scope in level {
            if range.location < scope.range.entireRange.location {
                return i
            }
            i++
        }
        return i
    }
}
