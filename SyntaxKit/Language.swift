//
//  Language.swift
//  SyntaxKit
//
//  Represents a textmate syntax file (.tmLanguage). Before use the 
//  validateWithHelperLanguages method has to be called on it.
//
//  Created by Sam Soffes on 9/18/14.
//  Copyright © 2014-2015 Sam Soffes. All rights reserved.
//

public struct Language {
    
    // MARK: - Properties
    
    public let UUID: String // TODO: replace with uuid type in swift 3
    public let name: String
    public let scopeName: String
    
    let pattern: Pattern = Pattern()
    let referenceManager = ReferenceManager()
    let repository: Repository
    
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
        self.repository = Repository(repo: dictionary["repository"] as? [String: [NSObject: AnyObject]] ?? [:], inParent: nil, withReferenceManager: referenceManager)
        referenceManager.resolveInternalReferences(repository, inLanguage: self)
    }
    
    /// Resolves all external reference the language has to the given languages.
    /// Only after a call to this method the Language is fit for general use.
    ///
    /// - parameter helperLanguages: The languages that the language has 
    ///     references to resolve against. This should at least contain the
    ///     language itself.
    mutating func validateWithHelperLanguages(helperLanguages: [Language]) {
        ReferenceManager.resolveExternalReferencesBetweenLanguages(helperLanguages, basename: self.scopeName)
    }
}
