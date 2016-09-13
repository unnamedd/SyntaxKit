//
//  TestHelper.swift
//  SyntaxKit
//
//  Created by Sam Soffes on 6/15/15.
//  Copyright © 2015 Sam Soffes. All rights reserved.
//

import Foundation
import XCTest
@testable import SyntaxKit

func fixture(_ name: String, _ type: String) -> String {
    if let path = Bundle(for: LanguageTests.self).path(forResource: name, ofType: type) {
        do {
            return try String(contentsOfFile: path)
        } catch {
            return ""
        }
    }
    return ""
}

func getBundleManager() -> BundleManager {
    return BundleManager { identifier, isLanguage in
        let name = isLanguage ? identifier._split(separator: ".")[1] : identifier
        let ext = isLanguage ? ".tmLanguage" : ".tmTheme"
        return Bundle(for: LanguageTests.self).url(forResource: name.capitalized, withExtension: ext) ?? URL(fileURLWithPath: "")
    }
}

func simpleTheme() -> Theme {
    return Theme(dictionary: [
        "uuid": "123e4567-e89b-12d3-a456-426655440000",
        "name": "Simple",
        "settings": [
            [
                "scope": "entity.name",
                "settings": [
                    "color": "blue"
                ]
            ],
            [
                "scope": "string",
                "settings": [
                    "color": "red"
                ]
            ],
            [
                "scope": "constant.numeric",
                "settings": [
                    "color": "purple"
                ]
            ]
        ]
    ])!
}

func replace(_ range: NSRange, in string: String, with inserted: String) -> String {
    let newInput = string.mutableCopy() as? NSMutableString
    newInput?.replaceCharacters(in: range, with: inserted)
    return newInput!.copy() as? String ?? ""
}

#if !os(OSX)
import UIKit
extension Color {
    var redComponent: CGFloat {
        var value: CGFloat = 0.0
        getRed(&value, green: nil, blue: nil, alpha: nil)
        return value
    }

    var greenComponent: CGFloat {
        var value: CGFloat = 0.0
        getRed(nil, green: &value, blue: nil, alpha: nil)
        return value
    }

    var blueComponent: CGFloat {
        var value: CGFloat = 0.0
        getRed(nil, green: nil, blue: &value, alpha: nil)
        return value
    }

    var alphaComponent: CGFloat {
        var value: CGFloat = 0.0
        getRed(nil, green: nil, blue: nil, alpha: &value)
        return value
    }
}
#endif

func assertEqualColors(_ color1: Color?, _ color2: Color?, accuracy: CGFloat = 0.005) {
    if color1 == nil || color2 == nil {
        XCTAssert(false, "colors have to be non-nil")
        return
    }
    XCTAssertEqualWithAccuracy(color1!.redComponent, color2!.redComponent, accuracy: accuracy)
    XCTAssertEqualWithAccuracy(color1!.greenComponent, color2!.greenComponent, accuracy: accuracy)
    XCTAssertEqualWithAccuracy(color1!.blueComponent, color2!.blueComponent, accuracy: accuracy)
    XCTAssertEqualWithAccuracy(color1!.alphaComponent, color2!.alphaComponent, accuracy: accuracy)
}

extension NSRange: Equatable {}

public func == (lhs: NSRange, rhs: NSRange) -> Bool {
    return lhs.location == rhs.location && lhs.length == rhs.length
}
