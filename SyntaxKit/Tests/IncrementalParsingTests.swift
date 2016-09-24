//
//  IncrementalParsingTests.swift
//  SyntaxKit
//
//  Created by Alexander Hedges on 27/01/16.
//  Copyright © 2016 Alexander Hedges. All rights reserved.
//

import XCTest
import SyntaxKit

class IncrementalParsingTests: XCTestCase {

    // MARK: - Properties

    let manager = getBundleManager()
    var parsingOperation: AttributedParsingOperation!
    var theme: Theme!
    var language: Language!
    var totalRange: NSRange?
    var input = ""


    // MARK: - Tests

    override func setUp() {
        super.setUp()
        language = manager.language(withIdentifier: "Source.swift")!
        theme = manager.theme(withIdentifier: "tomorrow")!

    }

    func testEdits() {
        input = fixture("swifttest.swift", "txt")
        parsingOperation = getParsingOperation()

        parsingOperation.main()
        XCTAssertEqual(totalRange!, NSRange(location: 0, length: (input as NSString).length))

        assertInsertion("i", location: 162, expectedRange: NSRange(location: 159, length: 5))

        assertDeletion(NSRange(location: 162, length: 1), expectedRange: NSRange(location: 159, length: 4))

        assertInsertion("756", location: 160, expectedRange: NSRange(location: 159, length: 7))
    }

    func testDeletion() {
        input = "Only this!"
        parsingOperation = getParsingOperation()

        parsingOperation.main()

        assertDeletion(NSRange(location: 9, length: 1), expectedRange: NSRange(location: 0, length: 9))
    }

    func testEdgeCase() {
        input = "// test.swift\n/**"
        parsingOperation = getParsingOperation()

        parsingOperation.main()
        XCTAssertEqual(totalRange, NSRange(location: 0, length: 17))

        assertDeletion(NSRange(location: 2, length: 1), expectedRange: NSRange(location: 0, length: 13))

        assertInsertion(" ", location: 2, expectedRange: NSRange(location: 0, length: 14))

        assertInsertion("\n", location: 17, expectedRange: NSRange(location: 14, length: 4))
    }

    func testPerformanceInScope() {
        input = fixture("swifttest.swift", "txt")
        parsingOperation = getParsingOperation()

        parsingOperation.main()

        self.measure {
            self.assertInsertion("Tests", location: 239, expectedRange: NSRange(location: 230, length: 24))

            self.assertDeletion(NSRange(location: 239, length: 5), expectedRange: NSRange(location: 230, length: 19))
        }
    }

    func testPerformanceEdgeCases() {
        input = fixture("swifttest.swift", "txt")
        parsingOperation = getParsingOperation()

        parsingOperation.main()

        self.measure {
            self.assertDeletion(NSRange(location: 139, length: 1), expectedRange: NSRange(location: 139, length: 22))

            self.assertInsertion("/", location: 139, expectedRange: NSRange(location: 139, length: 23))
        }
    }


    // MARK: - Helpers

    fileprivate func getParsingOperation() -> AttributedParsingOperation {
        return AttributedParsingOperation(string: input, language: language, theme: theme) { (results: [(range: NSRange, attributes: Attributes?)], sender: AttributedParsingOperation) in
            for result in results {
                if self.totalRange == nil {
                    self.totalRange = result.range
                } else {
                    self.totalRange = NSUnionRange(self.totalRange!, result.range)
                }
            }
        }
    }

    fileprivate func assertInsertion(_ string: String, location: Int, expectedRange expected: NSRange) {
        input = replace(NSRange(location: location, length: 0), in: input, with: string)
        parsingOperation = AttributedParsingOperation(string: input, previousOperation: parsingOperation, changeIsInsertion: true, changedRange: NSRange(location: location, length: (string as NSString).length))

        totalRange = nil
        parsingOperation.main()
        XCTAssertEqual(totalRange!, expected)
    }

    fileprivate func assertDeletion(_ range: NSRange, expectedRange expected: NSRange) {
        input = replace(range, in: input, with: "")
        parsingOperation = AttributedParsingOperation(string: input, previousOperation: parsingOperation, changeIsInsertion: false, changedRange: range)

        totalRange = nil
        parsingOperation.main()
        XCTAssertEqual(totalRange, expected)
    }
}
