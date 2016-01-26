//
//  ThemeTests.swift
//  SyntaxKit
//
//  Created by Sam Soffes on 6/15/15.
//  Copyright © 2015 Sam Soffes. All rights reserved.
//

import XCTest
@testable import SyntaxKit

class ThemeTests: XCTestCase {

    // MARK: - Properties

    let tomorrow = theme("Tomorrow")
    let solarized = theme("Solarized")

    // MARK: - Tests

    func testLoading() {
        XCTAssertEqual("82CCD69C-F1B1-4529-B39E-780F91F07604", tomorrow.UUID)
        XCTAssertEqual("Tomorrow", tomorrow.name)
        assertEqualColors(Color(hex: "#666969"), tomorrow.attributes["constant.other"]![NSForegroundColorAttributeName] as? Color)
        assertEqualColors(Color(hex: "#4271AE"), tomorrow.attributes["keyword.other.special-method"]![NSForegroundColorAttributeName] as? Color)
    }

    func testComplexTheme() {
        XCTAssertEqual("38E819D9-AE02-452F-9231-ECC3B204AFD7", solarized.UUID)
        XCTAssertEqual("Solarized (light)", solarized.name)
        assertEqualColors(Color(hex: "#2aa198"), solarized.attributes["string.quoted.double"]![NSForegroundColorAttributeName] as? Color)
        assertEqualColors(Color(hex: "#2aa198"), solarized.attributes["string.quoted.single"]![NSForegroundColorAttributeName] as? Color)
    }
}
