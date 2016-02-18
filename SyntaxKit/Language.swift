//
//  Language.swift
//  SyntaxKit
//
//  Created by Alexander Hedges on 17/02/16.
//  Copyright © 2016 Sam Soffes. All rights reserved.
//

import Foundation

public class Language {
    
    public var UUID: String = ""
    public var name: String = ""
    public var scopeName: String = ""
    var referenceManager = ReferenceManager()
    
    var pattern: Pattern = Pattern()
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
    
    func validateWithHelperLanguages(helperLanguages: [Language]) {
        let resolvedProtoLanguage = Language.resolveReferencesBetweenThisAndProtoLanguages(self, andOtherLanguages: helperLanguages)
        self.UUID = resolvedProtoLanguage.UUID
        self.name = resolvedProtoLanguage.name
        self.scopeName = resolvedProtoLanguage.scopeName
        self.pattern = resolvedProtoLanguage.pattern
    }
    
    private class func resolveReferencesBetweenThisAndProtoLanguages(thisLanguage: Language, andOtherLanguages otherLanguages: [Language]) -> Language {
        let newLanguage = thisLanguage
        var copyOfProtoLanguages: [Language] = []
        for language in otherLanguages {
            let newOtherLang = ReferenceManager.copyLanguage(language)
            copyOfProtoLanguages.append(newOtherLang)
        }
        ReferenceManager.resolveInterLanguageReferences(copyOfProtoLanguages, basename: thisLanguage.scopeName)
        return newLanguage
    }

}
