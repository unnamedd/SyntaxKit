//
//  SwiftBaselineHighlightingTests.swift
//  SyntaxKit
//
//  Created by Alexander Hedges on 19/01/16.
//  Copyright © 2016 Alexander Hedges. All rights reserved.
//

import Foundation
import XCTest
import SyntaxKit

class SwiftBaselineHighlightingTests: XCTestCase {

    // MARK: - Properties

    let manager = getBundleManager()
    var parser: AttributedParser!


    // MARK: - Tests

    override func setUp() {
        super.setUp()
        let swift = manager.language(withIdentifier: "source.Swift")!
        let solarized = manager.theme(withIdentifier: "Solarized")!
        parser = AttributedParser(language: swift, theme: solarized)
    }

    func testColors() {
        let input = fixture("swifttest.swift", "txt")
        let string = parser.attributedString(for: input)

        // line comment
        assertEqualColors(Color(hex: "#93A1A1"), string.attributes(at: 10, effectiveRange: nil)[NSForegroundColorAttributeName] as? Color)
        assertEqualColors(Color(hex: "#93A1A1"), string.attributes(at: 135, effectiveRange: nil)[NSForegroundColorAttributeName] as? Color)

        // block comment
//        print((string.string as NSString).substringWithRange(NSRange(location: 157, length: 20)))
        assertEqualColors(Color(hex: "#93A1A1"), string.attributes(at: 157, effectiveRange: nil)[NSForegroundColorAttributeName] as? Color)

        // string literal
//        print((string.string as NSString).substringWithRange(NSRange(location: 744, length: 6)))
        assertEqualColors(Color(hex: "#839496"), string.attributes(at: 744, effectiveRange: nil)[NSForegroundColorAttributeName] as? Color)
        var stringRange = NSRange()
        assertEqualColors(Color(hex: "#2aa198"), string.attributes(at: 745, effectiveRange: &stringRange)[NSForegroundColorAttributeName] as? Color)
        XCTAssertEqual(stringRange.length, 4)
        assertEqualColors(Color(hex: "#839496"), string.attributes(at: 749, effectiveRange: nil)[NSForegroundColorAttributeName] as? Color)

        // number literal
        var numberRange = NSRange()
//        print((string.string as NSString).substringWithRange(NSRange(location: 715, length: 3)))
        assertEqualColors(Color(hex: "#d33682"), string.attributes(at: 715, effectiveRange: &numberRange)[NSForegroundColorAttributeName] as? Color)
        XCTAssertEqual(numberRange, NSRange(location: 715, length: 1))
    }

    func testHighlightingPerformance() {
        let input = fixture("swifttest.swift", "txt")
        self.measure {
            _ = self.parser.attributedString(for: input)
        }
    }
}
