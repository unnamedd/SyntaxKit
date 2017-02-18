//
//  PerformanceTests.swift
//  SyntaxKit
//
//  Created by Alexander Hedges on 05.01.17.
//  Copyright © 2017 Sam Soffes. All rights reserved.
//

import SyntaxKit
import XCTest

class PerformanceTests: XCTestCase {

    // MARK: - Properties

    let manager = getBundleManager()
    var parser: AttributedParser!

    override func setUp() {
        super.setUp()
        let latex = manager.language(withIdentifier: "source.Latex")!
        let solarized = manager.theme(withIdentifier: "Solarized")!
        parser = AttributedParser(language: latex, theme: solarized)
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testLongTexFilePerformance() {
        let input = fixture("textest.tex", "txt")
        self.measure {
            _ = self.parser.attributedString(for: input)
        }
    }

}
