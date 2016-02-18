//
//  ProtoPattern.swift
//  SyntaxKit
//
//  Created by Alexander Hedges on 17/02/16.
//  Copyright © 2016 Sam Soffes. All rights reserved.
//

import UIKit

class ProtoPattern: NSObject {

    // MARK: - Properties
    
    var name: String?                       { return _name }
    var match: NSRegularExpression?         { return _match }
    var captures: CaptureCollection?        { return _captures }
    var begin: NSRegularExpression?         { return _begin }
    var beginCaptures: CaptureCollection?   { return _beginCaptures }
    var end: NSRegularExpression?           { return _end }
    var endCaptures: CaptureCollection?     { return _endCaptures }
    weak var parent: ProtoPattern?
    
    private var _name: String?
    private var _match: NSRegularExpression?
    private var _captures: CaptureCollection?
    private var _begin: NSRegularExpression?
    private var _beginCaptures: CaptureCollection?
    private var _end: NSRegularExpression?
    private var _endCaptures: CaptureCollection?
    var subpatterns: [ProtoPattern] = []
    
    private let debug = true
    
    
    // MARK: - Initializers
    
    init?(dictionary: [NSObject: AnyObject], parent: ProtoPattern?, withRepository repository: Repository?, withReferenceManager refman: ReferenceManager) {
        super.init()
        self.parent = parent
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
            if match != nil {
                _captures = CaptureCollection(dictionary: dictionary)
            } else if begin != nil && end != nil {
                _beginCaptures = CaptureCollection(dictionary: dictionary)
                _endCaptures = _beginCaptures
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
            subpatterns = refman.patternsForArray(array, inRepository: repository, caller: self)
        }
    }
    
    init(pattern: ProtoPattern, parent: ProtoPattern?) {
        super.init()
        _name = pattern.name
        _match = pattern.match
        _captures = pattern.captures
        _begin = pattern.begin
        _beginCaptures = pattern.beginCaptures
        _end = pattern.end
        _endCaptures = pattern.endCaptures
        self.parent = parent
        subpatterns = []
    }
    
    private override init() {
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

class Include: ProtoPattern {
    
    var type: referenceType
    private let repositoryRef: String?
    private let languageRef: String?
    private let associatedRepository: Repository?
    
    init(reference: String, inRepository repository: Repository? = nil, parent: ProtoPattern?) {
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
    
    init(include: Include, parent: ProtoPattern?) {
        self.type = include.type
        self.repositoryRef = include.repositoryRef
        self.languageRef = include.languageRef
        self.associatedRepository = include.associatedRepository
        super.init()
        _name = include.name
        _match = include.match
        _captures = include.captures
        _begin = include.begin
        _beginCaptures = include.beginCaptures
        _end = include.end
        _endCaptures = include.endCaptures
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
            let position = self.parent!.subpatterns.indexOf(isEqualToPattern)
            if position != nil {
                let newPatterns = flatCopyOfPatterns(language.patterns, inLanguage: language, newParent: self.parent!)
                self.parent!.subpatterns.replaceRange(NSRange(location: position!, length: 1).toRange()!, with: newPatterns)
            }
            self.type = .resolved
        }
    } 
    
    private func flatCopyOfPatterns(patterns: [ProtoPattern], inLanguage language: Language, newParent parent: ProtoPattern?) -> [ProtoPattern] {
        var result: [ProtoPattern] = []
        for pattern in patterns {
            let newPattern: ProtoPattern
            if pattern as? Include != nil && (pattern as! Include).type != .resolved {
                newPattern = Include(include: pattern as! Include, parent: parent)
                language.referenceManager.includes.append(newPattern as! Include)
            } else {
                newPattern = ProtoPattern(pattern: pattern, parent: parent)
            }
            newPattern.subpatterns = pattern.subpatterns
//            for subPattern in newPattern.subpatterns {
//                subPattern.parent = newPattern
//            }
            result.append(newPattern)
        }
        return result
    }
    
    func resolveInterLanguageReferences(ownLanguage: Language, inLanguages languages: [String: Language], baseName: String?) {
        if type == .toBase {
            let position = self.parent!.subpatterns.indexOf(isEqualToPattern)
            if position != nil {
                let baseLanguage = languages[baseName!]
                let newPatterns = flatCopyOfPatterns(baseLanguage!.patterns, inLanguage: ownLanguage, newParent: self.parent!)
                self.parent!.subpatterns.replaceRange(NSRange(location: position!, length: 1).toRange()!, with: newPatterns)
            }
            self.type = .resolved
        } else if type == .toForeignRepository {
            let newLanguage = languages[languageRef!]
            let pattern = newLanguage?.repository[repositoryRef!]
            if self.parent != nil {
                if let position = self.parent!.subpatterns.indexOf(isEqualToPattern) {
                    if pattern != nil {
                        self.parent!.subpatterns.replaceRange(NSRange(location: position, length: 1).toRange()!, with: [pattern!])
                    } else {
                        self.parent!.subpatterns.replaceRange(NSRange(location: position, length: 1).toRange()!, with: [])
                    }
                }
            } else {
                if let position = ownLanguage.patterns.indexOf(isEqualToPattern) {
                    if pattern != nil {
                        ownLanguage.patterns.replaceRange(NSRange(location: position, length: 1).toRange()!, with: [pattern!])
                    } else {
                        ownLanguage.patterns.replaceRange(NSRange(location: position, length: 1).toRange()!, with: [])
                    }
                }
            }
            self.type = .resolved
        } else if type == .toForeign {
            if let includedLang = languages[languageRef!] {
                let newPatterns = flatCopyOfPatterns(includedLang.patterns, inLanguage: ownLanguage, newParent: self.parent)
                if self.parent != nil {
                    if let position = self.parent!.subpatterns.indexOf(isEqualToPattern) {
                        self.parent!.subpatterns.replaceRange(NSRange(location: position, length: 1).toRange()!, with: newPatterns)
                    }
                } else {
                    if let position = ownLanguage.patterns.indexOf(isEqualToPattern) {
                        ownLanguage.patterns.replaceRange(NSRange(location: position, length: 1).toRange()!, with: newPatterns)
                    }
                }
            }
            self.type = .resolved
        }
    }
    
    private func isEqualToPattern(pattern: ProtoPattern) -> Bool {
        if let include = pattern as? Include  {
            return include.type == self.type && include.repositoryRef == self.repositoryRef && include.languageRef == self.languageRef
        }
        return false
    }
    
    // MARK: - Private
    
    private func replaceWithPattern(pattern: ProtoPattern) {
        _name = pattern._name
        _match = pattern.match
        _captures = pattern.captures
        _begin = pattern.begin
        _beginCaptures = pattern.beginCaptures
        _end = pattern.end
        _endCaptures = pattern.endCaptures
        subpatterns = pattern.subpatterns
    }
}
