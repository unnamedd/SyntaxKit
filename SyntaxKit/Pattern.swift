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

class Pattern: NSObject {
    
    // MARK: - Properties
    
    var name: String?
    var match: NSRegularExpression?
    var captures: CaptureCollection?
    var begin: NSRegularExpression?
    var beginCaptures: CaptureCollection?
    var end: NSRegularExpression?
    var endCaptures: CaptureCollection?
    weak var parent: Pattern?
    var subpatterns: [Pattern] = []
    
    private let debug = true
    
    
    // MARK: - Initializers
    
    init?(dictionary: [NSObject: AnyObject], parent: Pattern?, withRepository repository: Repository?, withReferenceManager refman: ReferenceManager) {
        super.init()
        self.parent = parent
        self.name = dictionary["name"] as? String
        
        if let matchExpr = dictionary["match"] as? String {
            self.match = try? NSRegularExpression(pattern: matchExpr, options:[.AnchorsMatchLines])
            if debug && self.match == nil {
                print("Problem parsing match expression \(matchExpr)")
            }
        }
        
        if let beginExpr = dictionary["begin"] as? String {
            self.begin = try? NSRegularExpression(pattern: beginExpr, options:[.AnchorsMatchLines])
            if debug && self.begin == nil {
                print("Problem parsing begin expression \(beginExpr)")
            }
        }
        
        if let endExpr = dictionary["end"] as? String {
            self.end = try? NSRegularExpression(pattern: endExpr, options:[.AnchorsMatchLines])
            if debug && self.end == nil {
                print("Problem parsing end expression \(endExpr)")
            }
        }
        
        if let dictionary = dictionary["beginCaptures"] as? [NSObject: AnyObject] {
            self.beginCaptures = CaptureCollection(dictionary: dictionary)
        }
        
        if let dictionary = dictionary["captures"] as? [NSObject: AnyObject] {
            if match != nil {
                self.captures = CaptureCollection(dictionary: dictionary)
            } else if begin != nil && end != nil {
                self.beginCaptures = CaptureCollection(dictionary: dictionary)
                self.endCaptures = self.beginCaptures
            }
        }
        
        if let dictionary = dictionary["endCaptures"] as? [NSObject: AnyObject] {
            self.endCaptures = CaptureCollection(dictionary: dictionary)
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
            subpatterns = refman.patternsForArray(array, inRepository: repository, caller: self)
        }
    }
    
    init(pattern: Pattern, parent: Pattern?) {
        super.init()
        self.name = pattern.name
        self.match = pattern.match
        self.captures = pattern.captures
        self.begin = pattern.begin
        self.beginCaptures = pattern.beginCaptures
        self.end = pattern.end
        self.endCaptures = pattern.endCaptures
        self.parent = parent
        subpatterns = []
    }
    
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
    
    var type: referenceType
    private let repositoryRef: String?
    private let languageRef: String?
    private let associatedRepository: Repository?
    
    init(reference: String, inRepository repository: Repository? = nil, parent: Pattern?) {
        self.associatedRepository = repository
        if reference.hasPrefix("#") {
            self.type = .toRepository
            self.repositoryRef = reference.substringFromIndex(reference.startIndex.successor())
            self.languageRef = nil
        } else if reference == "$self" {
            self.type = .toSelf
            self.repositoryRef = nil
            self.languageRef = nil
        } else  if reference == "$base" {
            self.type = .toBase
            self.repositoryRef = nil
            self.languageRef = nil
        } else if reference.containsString("#") {
            self.type = .toForeignRepository
            self.repositoryRef = reference.substringFromIndex(reference.rangeOfString("#")!.endIndex)
            self.languageRef = reference.substringToIndex(reference.rangeOfString("#")!.startIndex)
            BundleManager.defaultManager?.getProtoLanguageWithIdentifier(languageRef!)
        } else {
            self.type = .toForeign
            self.repositoryRef = nil
            self.languageRef = reference
            BundleManager.defaultManager?.getProtoLanguageWithIdentifier(languageRef!)
        }
        super.init()
        self.parent = parent
    }
    
    init(include: Include, parent: Pattern?) {
        self.type = include.type
        self.repositoryRef = include.repositoryRef
        self.languageRef = include.languageRef
        self.associatedRepository = include.associatedRepository
        super.init()
        self.name = include.name
        self.match = include.match
        self.captures = include.captures
        self.begin = include.begin
        self.beginCaptures = include.beginCaptures
        self.end = include.end
        self.endCaptures = include.endCaptures
        self.parent = parent
        subpatterns = []
    }
    
    func resolveRepositoryReferences(repository: Repository) {
        if type == .toRepository {
            if let pattern = (associatedRepository ?? repository)[repositoryRef!] {
                self.replaceWithPattern(pattern)
            }
            self.type = .resolved
        }
    }
    
    func resolveSelfReferences(language: Language) {
        if type == .toSelf {
            self.replaceWithPattern(language.pattern)
            self.type = .resolved
        }
    }
    
    func resolveInterLanguageReferences(ownLanguage: Language, inLanguages languages: [String: Language], baseName: String?) {
        let toReplacePattern: Pattern?
        if type == .toBase {
            toReplacePattern = languages[baseName!]!.pattern
        } else if type == .toForeignRepository {
            toReplacePattern = languages[languageRef!]?.repository[repositoryRef!]
        } else if type == .toForeign {
            toReplacePattern = languages[languageRef!]?.pattern
        } else {
            return
        }
        
        if toReplacePattern != nil {
            self.replaceWithPattern(toReplacePattern!)
        }
        self.type = .resolved
    }
        
    // MARK: - Private
    
    private func replaceWithPattern(pattern: Pattern) {
        self.name = pattern.name
        self.match = pattern.match
        self.captures = pattern.captures
        self.begin = pattern.begin
        self.beginCaptures = pattern.beginCaptures
        self.end = pattern.end
        self.endCaptures = pattern.endCaptures
        subpatterns = pattern.subpatterns
    }
}

