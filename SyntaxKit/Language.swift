//
//  Language.swift
//  SyntaxKit
//
//  Created by Alexander Hedges on 17/02/16.
//  Copyright © 2016 Sam Soffes. All rights reserved.
//

import Foundation

public struct Language {
    
    public let UUID: String//         {return _UUID}
    public let name: String//         {return _name}
    public let scopeName: String//    {return _scopeName}
    
//    private var _UUID = ""
//    private var _name = ""
//    private var _scopeName = ""
    
    var pattern: Pattern = Pattern()
    var referenceManager = ReferenceManager()
    var repository = Repository()
    
    static let globalScope = "GLOBAL"
    
    // MARK: - Initializers
    
    init?(dictionary: [NSObject: AnyObject]) {
        guard let UUID = dictionary["uuid"] as? String,
            name = dictionary["name"] as? String,
            scopeName = dictionary["scopeName"] as? String,
            array = dictionary["patterns"] as? [[NSObject: AnyObject]]
            else { return nil }
        
        self.UUID = UUID
        self.name = name
        self.scopeName = scopeName
        self.pattern.subpatterns = referenceManager.patternsForArray(array, inRepository: nil, caller: nil)
        self.repository = Repository(repo: dictionary["repository"] as? [String: [NSObject: AnyObject]] ?? [:], inParent: nil, inLanguage: self, withReferenceManager: referenceManager)
        referenceManager.resolveRepositoryReferences(repository)
        referenceManager.resolveSelfReferences(self)
    }
    
    mutating func validateWithHelperLanguages(helperLanguages: [Language]) {
        let resolvedProtoLanguage = resolveReferencesBetweenThisAndProtoLanguages(helperLanguages)
        self.pattern = resolvedProtoLanguage.pattern
    }
    
    private func resolveReferencesBetweenThisAndProtoLanguages(otherLanguages: [Language]) -> Language {
        let newLanguage = self
        var copyOfProtoLanguages: [Language] = []
        for language in otherLanguages {
            let newOtherLang = ReferenceManager.copyLanguage(language)
            copyOfProtoLanguages.append(newOtherLang)
        }
        ReferenceManager.resolveInterLanguageReferences(copyOfProtoLanguages, basename: self.scopeName)
        return newLanguage
    }
}
