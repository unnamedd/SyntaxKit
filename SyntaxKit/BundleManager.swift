//
//  BundleManager.swift
//  SyntaxKit
//
//  Used to get access to SyntaxKit representations of TextMate bundle files.
//  This class is used as a gateway for both internal and external use.
//  Alternatively a global instace can be used for convenience. It is
//  initialized with a callback that tells the bundle manager where to find the
//  files.
//
//  Created by Alexander Hedges on 15/02/16.
//  Copyright © 2016 Alexander Hedges. All rights reserved.
//

public class BundleManager {

    // MARK: - Types

    /// Given an identifier of a grammar file and the format returns a url to the resource.
    ///
    /// - parameter identifier: The identifier of the file. Used to map it to
    ///                         the name of the file.
    /// - parameter isLanguage: Whether the requested file stores a language
    ///                         (.tmLanguage)
    /// - returns:  A URL pointing to the resource, if found
    public typealias BundleLocationCallback = (identifier: String, isLanguage: Bool) -> (NSURL?)


    // MARK: - Properties

    /// You probably want to leave the languageCaching property set to true.
    ///
    /// - note: Setting it to false will not invalidate or purge the cache. This
    ///         has to be done separately using clearLanguageCache.
    public var languageCaching = true

    public static var defaultManager: BundleManager?

    private var bundleCallback: BundleLocationCallback
    private var dependencies: [Language] = []
    private var cachedLanguages: [String: Language] = [:]
    private var cachedThemes: [String: Theme] = [:]


    // MARK: - Initializers

    /// Used to initialize the default manager. Unless this is called the
    /// defaultManager property will be set to nil.
    ///
    /// - parameter callback:   The callback used to find the location of the
    ///                         textmate files.
    public class func initializeDefaultManagerWithLocationCallback(callback: BundleLocationCallback) {
        if defaultManager == nil {
            defaultManager = BundleManager(callback: callback)
        } else {
            defaultManager!.bundleCallback = callback
        }
    }

    public init(callback: BundleLocationCallback) {
        self.bundleCallback = callback
    }


    // MARK: - Public

    public func languageWithIdentifier(identifier: String) -> Language? {
        if let language = self.cachedLanguages[identifier] {
            return language
        }

        self.dependencies = []
        var language = self.getRawLanguageWithIdentifier(identifier)
        language?.validateWithHelperLanguages(self.dependencies)

        if languageCaching && language != nil {
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
            newTheme = Theme(dictionary: plist as [NSObject: AnyObject]) else {
                return nil
        }

        cachedThemes[identifier] = newTheme
        return newTheme
    }

    /// Clears the language cache. Use if low on memory.
    public func clearLanguageCache() {
        self.cachedLanguages = [:]
    }


    // MARK: - Internal Interface

    /// - parameter identifier: The identifier of the requested language.
    /// - returns:  The Language with unresolved extenal references, if found
    func getRawLanguageWithIdentifier(identifier: String) -> Language? {
        let indexOfStoredLanguage = self.dependencies.indexOf { (lang: Language) in lang.scopeName == identifier }

        if indexOfStoredLanguage != nil {
            return self.dependencies[indexOfStoredLanguage!]
        } else {
            guard let dictURL = self.bundleCallback(identifier: identifier, isLanguage: true),
                plist = NSDictionary(contentsOfURL: dictURL),
                newLanguage = Language(dictionary: plist as [NSObject: AnyObject], bundleManager: self) else {
                    return nil
            }

            self.dependencies.append(newLanguage)
            return newLanguage
        }
    }
}
