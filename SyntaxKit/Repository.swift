//
//  Repository.swift
//  SyntaxKit
//
//  Represents a repository dictionary from a TextMate grammar. This class
//  supports nested repositories as found in some grammars.
//
//  Created by Alexander Hedges on 09/01/16.
//  Copyright © 2016 Alexander Hedges. All rights reserved.
//

class Repository {

    // MARK: - Properties

    private var entries: [String: Pattern] = [:]
    private weak var parentRepository: Repository?


    // MARK: - Initializers

    init(repo: [String: [NSObject: AnyObject]], inParent parent: Repository?, withReferenceManager refman: ReferenceManager) {
        self.parentRepository = parent

        for (key, value) in repo {
            var subRepo: Repository?
            if let containedRepo = value["repository"] as? [String: [NSObject: AnyObject]] {
                 subRepo = Repository(repo: containedRepo, inParent: self, withReferenceManager: refman)
            }
            if let pattern = Pattern(dictionary: value, parent: nil, withRepository: subRepo, withReferenceManager: refman) {
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
