//
//  Pattern.swift
//  SyntaxKit
//
//  Created by Sam Soffes on 9/18/14.
//  Copyright © 2014-2015 Sam Soffes. All rights reserved.
//

import Foundation

class Pattern {

    // MARK: - Properties

    var name: String?
    var match: NSRegularExpression?
    var captures: CaptureCollection?
    var begin: NSRegularExpression?
    var beginCaptures: CaptureCollection?
    var end: NSRegularExpression?
    var endCaptures: CaptureCollection?
    var parent: Pattern?
    var patterns: [Pattern]

    var subpatterns: [Pattern] {
        return patterns
    }
    
    // MARK: - Initializers
    
    init() {
        self.name = nil
        self.match = nil
        self.captures = nil
        self.begin = nil
        self.beginCaptures = nil
        self.end = nil
        self.endCaptures = nil
        self.patterns = []

    }
    
    init?(dictionary: [NSObject: AnyObject], parent: Pattern?, withRepository repository: Repository?) {
        self.parent = parent
        self.name = dictionary["name"] as? String
        
        if let matchExpr = dictionary["match"] as? String {
            self.match = try? NSRegularExpression(pattern: matchExpr, options:[.AnchorsMatchLines]) //[.CaseInsensitive]
        } else {
            self.match = nil
        }
        
        if let beginExpr = dictionary["begin"] as? String {
            self.begin = try? NSRegularExpression(pattern: beginExpr, options:[.AnchorsMatchLines])
        } else {
            self.begin = nil
        }
        
        if let endExpr = dictionary["end"] as? String {
            self.end = try? NSRegularExpression(pattern: endExpr, options:[.AnchorsMatchLines])
        } else {
            self.end = nil
        }
        
        if let dictionary = dictionary["beginCaptures"] as? [NSObject: AnyObject] {
            self.beginCaptures = CaptureCollection(dictionary: dictionary)
        } else {
            self.beginCaptures = nil
        }
        
        if let dictionary = dictionary["captures"] as? [NSObject: AnyObject] {
            self.captures = CaptureCollection(dictionary: dictionary)
        } else {
            self.captures = nil
        }
        
        if let dictionary = dictionary["endCaptures"] as? [NSObject: AnyObject] {
            self.endCaptures = CaptureCollection(dictionary: dictionary)
        } else {
            self.endCaptures = nil
        }
        
        if let array = dictionary["patterns"] as? [[NSObject: AnyObject]] {
            self.patterns = []
            self.patterns = Patterns.patternsForArray(array, inRepository: repository, caller: self)
        } else {
            self.patterns = []
        }
        
        if dictionary["match"] as? String != nil && self.match == nil {
            return nil
        } else if dictionary["begin"] as? String != nil && (self.begin == nil || self.end == nil) {
            return nil
        }
        
        if self.match == nil && self.begin == nil && self.end == nil && (dictionary["patterns"] as? [[NSObject: AnyObject]] == nil || dictionary["patterns"] as! [[NSObject: AnyObject]] == []) {
            return nil
        }
    }
     
    func replaceWithPattern(pattern: Pattern) {
        self.name = pattern.name
        self.match = pattern.match
        self.captures = pattern.captures
        self.begin = pattern.begin
        self.beginCaptures = pattern.beginCaptures
        self.end = pattern.end
        self.endCaptures = pattern.endCaptures
        self.patterns = pattern.patterns ?? []
    }
}

func ==(lhs: Pattern, rhs: Pattern) -> Bool {
    if  lhs.name != rhs.name ||
        lhs.match != rhs.match ||
        lhs.begin != rhs.begin ||
        lhs.end != rhs.end {
            return false
    }
    return true
}
