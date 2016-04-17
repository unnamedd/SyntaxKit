//
//  BundleManager.swift
//  SyntaxKit
//
//  Created by Alexander Hedges on 15/02/16.
//  Copyright © 2016 Alexander Hedges. All rights reserved.
//

public class BundleManager {
    
    // MARK: - Types
    
    public typealias BundleLocationCallback = (identifier: String, isLanguage: Bool) -> (NSURL?)
    
    
    // MARK: - Properties
    
    public static var defaultManager: BundleManager?
    
    private var bundleCallback: BundleLocationCallback
    private var dependencies: [Language] = []
    private var cachedLanguages: [String: Language] = [:]
    private var cachedUnresolvedLanguages: [String: Language] = [:]
    private var cachedThemes: [String: Theme] = [:]
    
    
    // MARK: - Initializers
    
    public class func initializeDefaultManagerWithLocationCallback(callback: BundleLocationCallback) {
        defaultManager = BundleManager(callback: callback)
    }
    
    init(callback: BundleLocationCallback) {
        self.bundleCallback = callback
    }
    
    
    // MARK: - Public
    
    public func languageWithIdentifier(identifier: String) -> Language? {
        if let language = self.cachedLanguages[identifier] {
            return language
        }
        
        self.dependencies = []
        var language = self.getUnvalidatedLanguageWithIdentifier(identifier)!
        language.validateWithHelperLanguages(self.dependencies)
        
        self.cachedLanguages[identifier] = language
        return language
    }
    
    public func themeWithIdentifier(identifier: String) -> Theme? {
        if let theme = cachedThemes[identifier] {
            return theme
        }
        
        guard let dictURL = self.bundleCallback(identifier: identifier, isLanguage: false),
            plist = NSDictionary(contentsOfURL: dictURL),
            newTheme = Theme(dictionary: plist as [NSObject : AnyObject]) else {
                return nil
        }
        
        cachedThemes[identifier] = newTheme
        return newTheme
    }
    
    
    // MARK: - Internal Interface
    
    func getUnvalidatedLanguageWithIdentifier(identifier: String) -> Language? {
        if let language = cachedUnresolvedLanguages[identifier] {
            if self.dependencies.indexOf({$0.UUID == language.UUID}) == nil {
                self.dependencies.append(language)
            }
            return language
        }
        
        guard let dictURL = self.bundleCallback(identifier: identifier, isLanguage: true),
            plist = NSDictionary(contentsOfURL: dictURL),
            newLanguage = Language(dictionary: plist as [NSObject : AnyObject]) else {
                return nil
        }
        
        self.dependencies.append(newLanguage)
        cachedUnresolvedLanguages[identifier] = newLanguage
        return newLanguage
    }
}
