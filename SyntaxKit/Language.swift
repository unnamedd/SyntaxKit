//
//  Language.swift
//  SyntaxKit
//
//  Created by Sam Soffes on 9/18/14.
//  Copyright © 2014-2015 Sam Soffes. All rights reserved.
//

import Foundation

public struct Language {

    // MARK: - Properties

    public let UUID: String
    public let name: String
    public let scopeName: String
    var patterns: [Pattern]

    static let globalScope = "GLOBAL"

    // MARK: - Initializers

    public init?(dictionary: [NSObject: AnyObject]) {
        guard let UUID = dictionary["uuid"] as? String,
            name = dictionary["name"] as? String,
            scopeName = dictionary["scopeName"] as? String,
            array = dictionary["patterns"] as? [[NSObject: AnyObject]]
            else { return nil }

        self.UUID = UUID
        self.name = name
        self.scopeName = scopeName
        Patterns.reset()
        self.patterns = Patterns.patternsForArray(array, inRepository: nil, caller: nil)
        
        let repository: Repository
        if let repo = dictionary["repository"] as? [String: [NSObject: AnyObject]] {
            repository = Repository(repo: repo, inParent: nil, inLanguage: self)
        } else {
            repository = Repository(repo: [:], inParent: nil, inLanguage: self)
        }
        
        Patterns.resolveReferencesWithRepository(repository, inLanguage: self)
        Patterns.reset()
    }
}
