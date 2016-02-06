//
//  Patterns.swift
//  SyntaxKit
//
//  Created by Alexander Hedges on 09/01/16.
//  Copyright © 2016 Sam Soffes. All rights reserved.
//

import Foundation

class Patterns {
    
    private static var includes: [Include] = []
    
    class func reset() {
        self.includes = []
    }
    
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
    }
}
