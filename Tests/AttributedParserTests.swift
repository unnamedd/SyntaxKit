//
//  AttributedParserTests.swift
//  SyntaxKit
//
//  Created by Sam Soffes on 9/19/14.
//  Copyright © 2014-2015 Sam Soffes. All rights reserved.
//

import SyntaxKit
import XCTest

internal class AttributedParserTests: XCTestCase {

    // MARK: - Properties

    private let manager: BundleManager = getBundleManager()
    private var parser: AttributedParser?

    // MARK: - Tests

    override func setUp() {
        super.setUp()
        if let yaml = manager.language(withIdentifier: "source.YAML"),
            let theme = simpleTheme() {
            parser = AttributedParser(language: yaml, theme: theme)
        } else {
            XCTFail("Should be able to load yaml")
        }

    }

    func testParsing() {
        let string = parser?.attributedString(for: "title: Hello World\ncount: 42\n")

        XCTAssertEqual(["color": "blue"], string?.attributes(at: 0, effectiveRange: nil) as NSDictionary?)
        XCTAssertEqual(["color": "red"], string?.attributes(at: 7, effectiveRange: nil) as NSDictionary?)
        XCTAssertEqual(["color": "blue"], string?.attributes(at: 19, effectiveRange: nil) as NSDictionary?)
        XCTAssertEqual(["color": "purple"], string?.attributes(at: 25, effectiveRange: nil) as NSDictionary?)
    }
}
