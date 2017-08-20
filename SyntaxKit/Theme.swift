//
//  Theme.swift
//  SyntaxKit
//
//  Represents a TextMate theme file (.tmTheme). Currently only supports the
//  foreground text color attribute on a local scope.
//
//  Created by Sam Soffes on 10/11/14.
//  Copyright © 2014-2015 Sam Soffes. All rights reserved.
//

#if os(OSX)
    import AppKit
#else
    import UIKit
#endif

public typealias Attributes = [NSAttributedStringKey: Any]

public struct Theme {

    // MARK: - Properties

    public let uuid: UUID
    public let name: String
    public let attributes: [String: Attributes]

    public var backgroundColor: Color {
		return attributes[Language.globalScope]?[NSAttributedStringKey.backgroundColor] as? Color ?? Color.white
    }

    public var foregroundColor: Color {
		return attributes[Language.globalScope]?[NSAttributedStringKey.foregroundColor] as? Color ?? Color.black
    }

    // MARK: - Initializers

    init?(dictionary: [String: Any]) {
        guard let uuidString = dictionary["uuid"] as? String,
            let uuid = UUID(uuidString: uuidString),
            let name = dictionary["name"] as? String,
            let rawSettings = dictionary["settings"] as? [[String: AnyObject]]
            else { return nil }

        self.uuid = uuid
        self.name = name

        var attributes = [String: Attributes]()
        for raw in rawSettings {
            guard var setting = raw["settings"] as? [NSAttributedStringKey: Any] else { continue }

			if let value = setting.removeValue(forKey: NSAttributedStringKey(rawValue: "foreground")) as? String {
				setting[NSAttributedStringKey.foregroundColor] = Color(hex: value)
            }

			if let value = setting.removeValue(forKey: NSAttributedStringKey(rawValue: "background")) as? String {
				setting[NSAttributedStringKey.backgroundColor] = Color(hex: value)
            }

            if let patternIdentifiers = raw["scope"] as? String {
                for patternIdentifier in patternIdentifiers.components(separatedBy: ",") {
                    let key = patternIdentifier.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                    attributes[key] = setting
                }
            } else if !setting.isEmpty {
                attributes[Language.globalScope] = setting
            }
        }
        self.attributes = attributes
    }
}
