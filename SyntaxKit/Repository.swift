//
//  Repository.swift
//  SyntaxKit
//
//  Created by Alexander Hedges on 09/01/16.
//  Copyright © 2016 Sam Soffes. All rights reserved.
//

import Foundation

class Repository {
    
    // MARK: - Properties
    
    private var entries: [String: Pattern]
    private weak var parentRepository: Repository?
    
    
    // MARK: - Initializers
    
    init(repo: [String: [NSObject: AnyObject]], inParent parent: Repository?, inLanguage language: Language) {
        self.entries = [:]
        self.parentRepository = parent
        
        for (key, value) in repo {
            var subRepo: Repository?
            if let containedRepo = value["repository"] as? [String: [NSObject: AnyObject]] {
                 subRepo = Repository(repo: containedRepo, inParent: self, inLanguage: language)
            }
            if let pattern = Pattern(dictionary: value, parent: nil, withRepository: subRepo) {
                self.entries[key] = pattern
            }
        }
    }
    
    
    // MARK: - Accessing Patterns
    
    subscript(index: String) -> Pattern? {
        if let resultAtLevel = entries[index] {
            return resultAtLevel
        }
        return parentRepository?[index]
    }
}
