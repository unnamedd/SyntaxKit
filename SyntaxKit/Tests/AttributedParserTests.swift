//
//  AttributedParserTests.swift
//  SyntaxKitTests
//
//  Created by Sam Soffes on 9/19/14.
//  Copyright © 2014-2015 Sam Soffes. All rights reserved.
//

import XCTest
import SyntaxKit

class AttributedParserTests: XCTestCase {

    // MARK: - Properties

    let manager = getBundleManager()
    var parser: AttributedParser!

    // MARK: - Tests

    override func setUp() {
        super.setUp()
        let yaml = manager.language(withIdentifier: "source.YAML")!
        parser = AttributedParser(language: yaml, theme: simpleTheme())
    }

    func testParsing() {
        let string = parser.attributedString(for: "title: Hello World\ncount: 42\n")

        XCTAssertEqual(["color": "blue"] as NSDictionary, string.attributes(at: 0, effectiveRange: nil) as NSDictionary)
        XCTAssertEqual(["color": "red"] as NSDictionary, string.attributes(at: 7, effectiveRange: nil) as NSDictionary)
        XCTAssertEqual(["color": "blue"] as NSDictionary, string.attributes(at: 19, effectiveRange: nil) as NSDictionary)
        XCTAssertEqual(["color": "purple"] as NSDictionary, string.attributes(at: 25, effectiveRange: nil) as NSDictionary)
    }
}
