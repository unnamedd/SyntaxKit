//
//  Theme.swift
//  SyntaxKit
//
//  Created by Sam Soffes on 10/11/14.
//  Copyright © 2014-2015 Sam Soffes. All rights reserved.
//

import Foundation

#if os(iOS) || os(watchOS)
    import UIKit
#endif

public typealias Attributes = [String: AnyObject]

public struct Theme {
    
    // MARK: - Properties
    
    public let UUID: String
    public let name: String
    public let attributes: [String: Attributes]
    
    public var backgroundColor: UIColor {
        if let color = attributes[Language.globalScope]?[NSBackgroundColorAttributeName] as? UIColor {
            return color
        } else {
            return UIColor.whiteColor()
        }
    }
    
    public var foregroundColor: UIColor {
        if let color = attributes[Language.globalScope]?[NSForegroundColorAttributeName] as? UIColor {
            return color
        } else {
            return UIColor.blackColor()
        }
    }
    
    // MARK: - Initializers
    
    init?(dictionary: [NSObject: AnyObject]) {
        guard let UUID = dictionary["uuid"] as? String,
            name = dictionary["name"] as? String,
            rawSettings = dictionary["settings"] as? [[String: AnyObject]]
            else { return nil }
        
        self.UUID = UUID
        self.name = name
        
        var attributes = [String: Attributes]()
        for raw in rawSettings {
            guard var setting = raw["settings"] as? [String: AnyObject] else { continue }
            
            if let value = setting.removeValueForKey("foreground") as? String {
                setting[NSForegroundColorAttributeName] = Color(hex: value)
            }
            
            if let value = setting.removeValueForKey("background") as? String {
                setting[NSBackgroundColorAttributeName] = Color(hex: value)
            }
            
            // TODO: caret, invisibles, lightHighlight, selection, font style
            
            if let patternIdentifiers = raw["scope"] as? String {
                for patternIdentifier in patternIdentifiers.componentsSeparatedByString(",") {
                    let key = patternIdentifier.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
                    attributes[key] = setting
                }
            } else if !setting.isEmpty {
                attributes[Language.globalScope] = setting
            }
        }
        self.attributes = attributes
    }
}
