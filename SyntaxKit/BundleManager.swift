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
    
    public var languageCaching = true
    
    public static var defaultManager: BundleManager?
    
    private var bundleCallback: BundleLocationCallback
    private var dependencies: [Language] = []
    private var cachedLanguages: [String: Language] = [:]
    private var cachedThemes: [String: Theme] = [:]
    
    
    // MARK: - Initializers
    
    public class func initializeDefaultManagerWithLocationCallback(callback: BundleLocationCallback) {
        if defaultManager == nil {
            defaultManager = BundleManager(callback: callback)
        } else {
            defaultManager!.bundleCallback = callback
        }
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
        
        if languageCaching {
            self.cachedLanguages[identifier] = language
        }
        
        self.dependencies = []
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
    
    public func clearLanguageCache() {
        self.cachedLanguages = [:]
    }
    
    
    // MARK: - Internal Interface
    
    func getUnvalidatedLanguageWithIdentifier(identifier: String) -> Language? {
        let indexOfStoredLanguage = self.dependencies.indexOf{ (lang: Language) in lang.scopeName == identifier }
        
        if indexOfStoredLanguage != nil {
            return self.dependencies[indexOfStoredLanguage!]
        } else {
            guard let dictURL = self.bundleCallback(identifier: identifier, isLanguage: true),
                plist = NSDictionary(contentsOfURL: dictURL),
                newLanguage = Language(dictionary: plist as [NSObject : AnyObject]) else {
                    return nil
            }
            
            self.dependencies.append(newLanguage)
            return newLanguage
        }
    }
}
