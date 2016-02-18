//
//  BundleManager.swift
//  SyntaxKit
//
//  Created by Alexander Hedges on 15/02/16.
//  Copyright © 2016 Alexander Hedges. All rights reserved.
//

import UIKit

public class BundleManager {
    
    public typealias BundleLocationCallback = (identifier: String, isLanguage: Bool) -> (NSURL?)
    
    private var bundleCallback: BundleLocationCallback
    private var dependencies: [Language] = []
    private var cachedLanguages: [String: Language] = [:]
    private var cachedProtoLanguages: [String: Language] = [:]
    private var cachedThemes: [String: Theme] = [:]
    
    public static var defaultManager: BundleManager?
    
    public class func initializeGlobalManagerWithCallback(callback: BundleLocationCallback) {
        defaultManager = BundleManager(callback: callback)
    }
    
    init(callback: BundleLocationCallback) {
        self.bundleCallback = callback
    }
    
    public func getLanguageWithIdentifier(identifier: String) -> Language? {
        if let language = self.cachedLanguages[identifier] {
            return language
        }
        
        self.dependencies = []
        let language = self.getProtoLanguageWithIdentifier(identifier)!
        language.validateWithHelperLanguages(self.dependencies)
        
        self.cachedLanguages[identifier] = language
        return language
    }
    
    func getProtoLanguageWithIdentifier(identifier: String) -> Language? {
        if let language = cachedProtoLanguages[identifier] {
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
        cachedProtoLanguages[identifier] = newLanguage
        return newLanguage
    }
    
    public func getThemeWithIdentifier(identifier: String) -> Theme? {
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
}
