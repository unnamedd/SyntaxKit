//
//  Pattern.swift
//  SyntaxKit
//
//  Represents a pattern from a TextMate grammar
//
//  The Include class represents a Pattern that is a reference to another part
//  in the same or another grammar. It is only usable as a pattern after it has
//  been resolved via the provided method (and has type .resolved).
//
//  A pattern may be one of three types:
//  *   A single pattern in match which should be matched
//  *   A begin and an end pattern containing an optional body of patterns
//      (subpatterns) which should be matched between the begin and the end
//  *   Only a body of patterns without the begin and end. Any pattern may be
//      matched successfully
//
//  Created by Sam Soffes on 9/18/14.
//  Copyright © 2014-2015 Sam Soffes. All rights reserved.
//

@objc(SKPattern)
class Pattern: NSObject {
    
    // MARK: - Properties
    
    var name: String?                       { return _name }
    var match: NSRegularExpression?         { return _match }
    var captures: CaptureCollection?        { return _captures }
    var begin: NSRegularExpression?         { return _begin }
    var beginCaptures: CaptureCollection?   { return _beginCaptures }
    var end: NSRegularExpression?           { return _end }
    var endCaptures: CaptureCollection?     { return _endCaptures }
    var applyEndPatternLast: Bool           { return _applyEndPatternLast}
    var parent: Pattern?                    { return _parent }
    var subpatterns: [Pattern] = []
    
    private var _name: String?
    private var _match: NSRegularExpression?
    private var _captures: CaptureCollection?
    private var _begin: NSRegularExpression?
    private var _beginCaptures: CaptureCollection?
    private var _end: NSRegularExpression?
    private var _endCaptures: CaptureCollection?
    private var _applyEndPatternLast = false
    private weak var _parent: Pattern?
    
    private let debug = true
    
    
    // MARK: - Initializers
    
    init?(dictionary: [NSObject: AnyObject], parent: Pattern?, withRepository repository: Repository?, withReferenceManager refman: ReferenceManager) {
        super.init()
        _parent = parent
        _name = dictionary["name"] as? String
        
        if let matchExpr = dictionary["match"] as? String {
            _match = try? NSRegularExpression(pattern: matchExpr, options:[.AnchorsMatchLines])
            if debug && self.match == nil {
                print("Problem parsing match expression \(matchExpr)")
            }
        }
        
        if let beginExpr = dictionary["begin"] as? String {
            _begin = try? NSRegularExpression(pattern: beginExpr, options:[.AnchorsMatchLines])
            if debug && self.begin == nil {
                print("Problem parsing begin expression \(beginExpr)")
            }
        }
        
        if let endExpr = dictionary["end"] as? String {
            _end = try? NSRegularExpression(pattern: endExpr, options:[.AnchorsMatchLines])
            if debug && self.end == nil {
                print("Problem parsing end expression \(endExpr)")
            }
        }
        
        _applyEndPatternLast = dictionary["applyEndPatternLast"] as? Bool ?? false
                
        if let dictionary = dictionary["beginCaptures"] as? [NSObject: AnyObject] {
            _beginCaptures = CaptureCollection(dictionary: dictionary)
        }
        
        if let dictionary = dictionary["captures"] as? [NSObject: AnyObject] {
            if match != nil {
                _captures = CaptureCollection(dictionary: dictionary)
            } else if begin != nil && end != nil {
                _beginCaptures = CaptureCollection(dictionary: dictionary)
                _endCaptures = self.beginCaptures
            }
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
            self.subpatterns = refman.patternsForArray(array, inRepository: repository, caller: self)
        }
    }
    
    init(pattern: Pattern, parent: Pattern?) {
        super.init()
        _name = pattern.name
        _match = pattern.match
        _captures = pattern.captures
        _begin = pattern.begin
        _beginCaptures = pattern.beginCaptures
        _end = pattern.end
        _endCaptures = pattern.endCaptures
        _parent = parent
        self.subpatterns = []
    }
    
    /// For most cases does not create a usable pattern.
    override init() {
        super.init()
    }
}

enum referenceType {
    case toRepository
    case toSelf
    case toBase
    case toForeign
    case toForeignRepository
    case resolved
}

class Include: Pattern {
    
    // MARK: - Properties
    
    var type: referenceType     {return _type}
    
    private var _type: referenceType
    private let repositoryRef: String?
    private let languageRef: String?
    private var associatedRepository: Repository?
    
    
    // MARK: - Initializers
    
    init(reference: String, inRepository repository: Repository? = nil, parent: Pattern?, bundleManager: BundleManager) {
        self.associatedRepository = repository
        if reference.hasPrefix("#") {
            self._type = .toRepository
            self.repositoryRef = reference.substringFromIndex(reference.startIndex.successor())
            self.languageRef = nil
        } else if reference == "$self" {
            self._type = .toSelf
            self.repositoryRef = nil
            self.languageRef = nil
        } else  if reference == "$base" {
            self._type = .toBase
            self.repositoryRef = nil
            self.languageRef = nil
        } else if reference.containsString("#") {
            self._type = .toForeignRepository
            self.repositoryRef = reference.substringFromIndex(reference.rangeOfString("#")!.endIndex)
            self.languageRef = reference.substringToIndex(reference.rangeOfString("#")!.startIndex)
            bundleManager.getRawLanguageWithIdentifier(languageRef!)
        } else {
            self._type = .toForeign
            self.repositoryRef = nil
            self.languageRef = reference
            bundleManager.getRawLanguageWithIdentifier(languageRef!)
        }
        super.init()
        _parent = parent
    }
    
    init(include: Include, parent: Pattern?) {
        self._type = include.type
        self.repositoryRef = include.repositoryRef
        self.languageRef = include.languageRef
        self.associatedRepository = include.associatedRepository
        super.init(pattern: include, parent: parent)
    }
    
    
    // MARK: - Reference Resolution
    
    func resolveInternalReference(repository: Repository, inLanguage language: Language) {
        let pattern: Pattern?
        if type == .toRepository {
            pattern = (associatedRepository ?? repository)[repositoryRef!]
        } else if type == .toSelf {
            pattern = language.pattern
        } else {
            return
        }
        
        if pattern != nil {
            self.replaceWithPattern(pattern!)
        }
        _type = .resolved
    }
    
    func resolveExternalReference(thisLanguage: Language, inLanguages languages: [String: Language], baseName: String?) {
        let pattern: Pattern?
        if type == .toBase {
            pattern = languages[baseName!]!.pattern
        } else if type == .toForeignRepository {
            pattern = languages[languageRef!]?.repository[repositoryRef!]
        } else if type == .toForeign {
            pattern = languages[languageRef!]?.pattern
        } else {
            return
        }
        
        if pattern != nil {
            self.replaceWithPattern(pattern!)
        }
        _type = .resolved
    }
    
        
    // MARK: - Private
    
    private func replaceWithPattern(pattern: Pattern) {
        _name = pattern.name
        _match = pattern.match
        _captures = pattern.captures
        _begin = pattern.begin
        _beginCaptures = pattern.beginCaptures
        _end = pattern.end
        _endCaptures = pattern.endCaptures
        self.subpatterns = pattern.subpatterns
    }
}

