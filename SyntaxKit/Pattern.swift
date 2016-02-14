//
//  Pattern.swift
//  SyntaxKit
//
//  Represents a pattern from a TextMate Language Bundle
//
//  The Include class represents a Pattern that is a reference to another part
//  of the Bundle. It is only fully functional as a pattern after it has been 
//  resolved via the provided method.
//
//  Created by Sam Soffes on 9/18/14.
//  Copyright © 2014-2015 Sam Soffes. All rights reserved.
//

import Foundation

class Pattern {
    
    // MARK: - Properties
    
    var name: String?                       { return _name }
    var match: NSRegularExpression?         { return _match }
    var captures: CaptureCollection?        { return _captures }
    var begin: NSRegularExpression?         { return _begin }
    var beginCaptures: CaptureCollection?   { return _beginCaptures }
    var end: NSRegularExpression?           { return _end }
    var endCaptures: CaptureCollection?     { return _endCaptures }
    var parent: Pattern?                    { return _parent }
    var subpatterns: [Pattern]              { return _subpatterns }
    
    private var _name: String?
    private var _match: NSRegularExpression?
    private var _captures: CaptureCollection?
    private var _begin: NSRegularExpression?
    private var _beginCaptures: CaptureCollection?
    private var _end: NSRegularExpression?
    private var _endCaptures: CaptureCollection?
    private var _parent: Pattern?
    private var _subpatterns: [Pattern] = []
    
    private let debug = true
    
    
    // MARK: - Initializers
    
    init?(dictionary: [NSObject: AnyObject], parent: Pattern?, withRepository repository: Repository?) {
        _parent = parent
        _name = dictionary["name"] as? String
        
        if let matchExpr = dictionary["match"] as? String {
            _match = try? NSRegularExpression(pattern: matchExpr, options:[.AnchorsMatchLines])
            if debug && _match == nil {
                print("Problem parsing match expression \(matchExpr)")
            }
        }
        
        if let beginExpr = dictionary["begin"] as? String {
            _begin = try? NSRegularExpression(pattern: beginExpr, options:[.AnchorsMatchLines])
            if debug && _begin == nil {
                print("Problem parsing begin expression \(beginExpr)")
            }
        }
        
        if let endExpr = dictionary["end"] as? String {
            _end = try? NSRegularExpression(pattern: endExpr, options:[.AnchorsMatchLines])
            if debug && _end == nil {
                print("Problem parsing end expression \(endExpr)")
            }
        }
        
        if let dictionary = dictionary["beginCaptures"] as? [NSObject: AnyObject] {
            _beginCaptures = CaptureCollection(dictionary: dictionary)
        }
        
        if let dictionary = dictionary["captures"] as? [NSObject: AnyObject] {
            _captures = CaptureCollection(dictionary: dictionary)
        }
        
        if let dictionary = dictionary["endCaptures"] as? [NSObject: AnyObject] {
            _endCaptures = CaptureCollection(dictionary: dictionary)
        }
        
        if dictionary["match"] as? String != nil && self.match == nil {
            return nil
        } else if dictionary["begin"] as? String != nil && (self.begin == nil || self.end == nil) {
            return nil
        }
        
        if self.match == nil &&
            self.begin == nil &&
            self.end == nil &&
            (dictionary["patterns"] as? [[NSObject: AnyObject]] == nil || dictionary["patterns"] as! [[NSObject: AnyObject]] == []) {
                print("Attention: pattern not recognized: \(self.name)")
                return nil
        }
        
        if let array = dictionary["patterns"] as? [[NSObject: AnyObject]] {
            _subpatterns = Patterns.patternsForArray(array, inRepository: repository, caller: self)
        }
    }
    
    private init() {}
}


class Include: Pattern {
    
    // MARK: - Properties
    
    private let referenceName: String
    private var associatedRepository: Repository?
    
    
    // MARK: - Initializers
    
    init(reference: String, inRepository repository: Repository? = nil, parent: Pattern?) {
        self.referenceName = reference
        self.associatedRepository = repository
        super.init()
        self._parent = parent
    }
    
    
    // MARK: - Public
    
    func resolveReferenceWithRepository(repository: Repository, inLanguage language: Language) {
        if referenceName.hasPrefix("#") {
            let key = referenceName.substringFromIndex(referenceName.startIndex.successor())
            if let pattern = (associatedRepository ?? repository)[key] {
                self.replaceWithPattern(pattern)
            }
        } else if referenceName == "$self" {
            let position = self.parent!.subpatterns.indexOf { [unowned self] pattern in
                if let include = pattern as? Include  {
                    return include.referenceName == self.referenceName
                }
                return false
            }
            self.parent!._subpatterns.replaceRange(NSRange(location: position!, length: 1).toRange()!, with: language.patterns)
        } else {
            // TODO: import from other language
        }
        self.associatedRepository = nil
    }
    
    
    // MARK: - Private
    
    private func replaceWithPattern(pattern: Pattern) {
        _name = pattern._name
        _match = pattern.match
        _captures = pattern.captures
        _begin = pattern.begin
        _beginCaptures = pattern.beginCaptures
        _end = pattern.end
        _endCaptures = pattern.endCaptures
        _subpatterns = pattern._subpatterns
    }
}
