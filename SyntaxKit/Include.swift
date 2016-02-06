//
//  Include.swift
//  SyntaxKit
//
//  TODO: add support for more sophisticiated includes
//
//  Created by Alexander Hedges on 09/01/16.
//  Copyright © 2016 Sam Soffes. All rights reserved.
//

import Foundation

class Include: Pattern {
    
    private let referenceName: String
    private var associatedRepository: Repository?
    
    init(reference: String, inRepository repository: Repository? = nil, parent: Pattern?) {
        self.referenceName = reference
        self.associatedRepository = repository
        super.init()
        self.parent = parent
    }
    
    func resolveReferenceWithRepository(repository: Repository, inLanguage language: Language) {
        if referenceName.hasPrefix("#") {
            let key = referenceName.substringFromIndex(referenceName.startIndex.successor())
            if let pattern = (associatedRepository ?? repository)[key] {
                self.replaceWithPattern(pattern)
            }
        } else if referenceName == "$self" {
            self.parent!.patterns = language.patterns
        } else {
            // TODO: import from other language
        }
        self.associatedRepository = nil
    }
}
