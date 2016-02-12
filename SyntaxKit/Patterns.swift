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
//  patterns.
//
//  Created by Alexander Hedges on 09/01/16.
//  Copyright © 2016 Alexander Hedges. All rights reserved.
//

import Foundation

class Patterns {
    
    private static var includes: [Include] = []
    
    class func patternsForArray(patterns: [[NSObject: AnyObject]], inRepository repository: Repository?, caller: Pattern?) -> [Pattern] {
        var results: [Pattern] = []
        for rawPattern in patterns {
            if let include = rawPattern["include"] as? String {
                let reference = Include(reference: include, inRepository: repository, parent: caller)
                self.includes.append(reference)
                results.append(reference)
            } else if let pattern = Pattern(dictionary: rawPattern, parent: caller, withRepository: repository) {
                results.append(pattern)
            }
        }
        return results
    }
    
    class func resolveReferencesWithRepository(repository: Repository, inLanguage language: Language) {
        for include in self.includes {
            include.resolveReferenceWithRepository(repository, inLanguage: language)
        }
        self.includes = []
    }
}
