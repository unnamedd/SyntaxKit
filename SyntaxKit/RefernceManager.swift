//
//  Patterns.swift
//  SyntaxKit
//
//  A utility class to facilitate the creation of pattern arrays.
//  It works it the following fashion: First all the pattern arrays should be 
//  created with patternsForArray:inRepository:caller:. Then
//  resolveReferencesWithRepository:inLanguage: has to be called to resolve all
//  the references in the passed out patterns. So first lots of calls to 
//  patternsForArray and then one call to resolveReferences to validate the
//  patterns by resolving all references.
//
//  Created by Alexander Hedges on 09/01/16.
//  Copyright © 2016 Alexander Hedges. All rights reserved.
//

import Foundation

class ReferenceManager {
    
    var includes: [Include] = []
    
    init() {}
    
    func patternsForArray(patterns: [[NSObject: AnyObject]], inRepository repository: Repository?, caller: Pattern?) -> [Pattern] {
        var results: [Pattern] = []
        for rawPattern in patterns {
            if let include = rawPattern["include"] as? String {
                let reference = Include(reference: include, inRepository: repository, parent: caller)
                self.includes.append(reference)
                results.append(reference)
            } else if let pattern = Pattern(dictionary: rawPattern, parent: caller, withRepository: repository, withReferenceManager: self) {
                results.append(pattern)
            }
        }
        return results
    }
    
    func resolveRepositoryReferences(repository: Repository) {
        for include in includes where include.type == .toRepository {
            include.resolveRepositoryReferences(repository)
        }
    }
    
    func resolveSelfReferences(language: Language) {
        for include in includes where include.type == .toSelf {
            include.resolveSelfReferences(language)
        }
    }
    
    class func resolveInterLanguageReferences(languages: [Language], basename: String) {
        var otherLanguages: [String: Language] = [:]
        for language in languages {
            otherLanguages[language.scopeName] = language
        }
        for language in languages {
            let includes = language.referenceManager.includes
            for include in includes where include.type == .toBase || include.type == .toForeign || include.type == .toForeignRepository {
                include.resolveInterLanguageReferences(language, inLanguages: otherLanguages, baseName: basename)
            }
        }
    }
    
    class func copyLanguage(language: Language) -> Language {
        let newLanguage = language
        newLanguage.referenceManager.includes = []
        newLanguage.pattern.subpatterns = ReferenceManager.copyPatternTree(language.pattern.subpatterns, inLanguage: newLanguage)
        return newLanguage
    }
    
    private class func copyPatternTree(patterns: [Pattern], parent: Pattern? = nil, foundPatterns: [Pattern: Pattern] = [:], inLanguage language: Language) -> [Pattern] {
        var newFoundPatterns = foundPatterns
        var result: [Pattern] = []
        for pattern in patterns {
            if let visitedPattern = foundPatterns[pattern] {
                result.append(visitedPattern)
            } else {
                let newPattern: Pattern
                if pattern as? Include != nil && (pattern as! Include).type != .resolved {
                    newPattern = Include(include: pattern as! Include, parent: parent)
                    language.referenceManager.includes.append(newPattern as! Include)
                } else {
                    newPattern = Pattern(pattern: pattern, parent: parent)
                }
                newFoundPatterns[pattern] = newPattern
                newPattern.subpatterns = copyPatternTree(pattern.subpatterns, parent: newPattern, foundPatterns: newFoundPatterns, inLanguage: language)
                result.append(newPattern)
            }
        }
        return result
    }
}
