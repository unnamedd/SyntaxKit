//
//  ThemeTests.swift
//  SyntaxKit
//
//  Created by Sam Soffes on 6/15/15.
//  Copyright © 2015 Sam Soffes. All rights reserved.
//

@testable import SyntaxKit
import XCTest

internal class ThemeTests: XCTestCase {

    // MARK: - Properties

    fileprivate let manager: BundleManager = getBundleManager()

    // MARK: - Tests

    func testLoading() {
        if let tomorrow = manager.theme(withIdentifier: "Tomorrow") {
            XCTAssertEqual(UUID(uuidString: "82CCD69C-F1B1-4529-B39E-780F91F07604"), tomorrow.uuid)
            XCTAssertEqual("Tomorrow", tomorrow.name)
            assertEqualColors(Color(hex: "#666969"), tomorrow.attributes["constant.other"]?[NSForegroundColorAttributeName] as? Color)
            assertEqualColors(Color(hex: "#4271AE"), tomorrow.attributes["keyword.other.special-method"]?[NSForegroundColorAttributeName] as? Color)
        } else {
            XCTFail()
        }
    }

    func testComplexTheme() {
        if let solarized = manager.theme(withIdentifier: "Solarized") {
            XCTAssertEqual(UUID(uuidString: "38E819D9-AE02-452F-9231-ECC3B204AFD7"), solarized.uuid)
            XCTAssertEqual("Solarized (light)", solarized.name)
            assertEqualColors(Color(hex: "#2aa198"), solarized.attributes["string.quoted.double"]?[NSForegroundColorAttributeName] as? Color)
            assertEqualColors(Color(hex: "#2aa198"), solarized.attributes["string.quoted.single"]?[NSForegroundColorAttributeName] as? Color)
        } else {
            XCTFail()
        }
    }
}
