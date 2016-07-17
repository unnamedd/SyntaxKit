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
        language = manager.languageWithIdentifier("Source.swift")!
        theme = manager.themeWithIdentifier("tomorrow")!

    }
    
    func testEdits() {
        input = fixture("swifttest.swift", "txt")
        parsingOperation = getParsingOperation()

        parsingOperation.main()
        XCTAssertEqual(totalRange!, NSRange(location: 0, length: (input as NSString).length))
        
        testInsertion("i", location: 162, expectedRange: NSRange(location: 159, length: 5))
        
        testDeletion(NSRange(location: 162, length: 1), expectedRange: NSRange(location: 159, length: 4))
        
        testInsertion("756", location: 160, expectedRange: NSRange(location: 159, length: 7))
    }
    
    func testEdgeCase() {
        input = "// test.swift\n/**"
        parsingOperation = getParsingOperation()
        
        parsingOperation.main()
        XCTAssertEqual(totalRange, NSRange(location: 0, length: 17))
        
        testDeletion(NSRange(location: 2, length: 1), expectedRange: NSRange(location: 0, length: 13))

        testInsertion(" ", location: 2, expectedRange: NSRange(location: 0, length: 14))
        
        testInsertion("\n", location: 17, expectedRange: NSRange(location: 14, length: 4))
    }
    
    func testPerformanceInScope() {
        input = fixture("swifttest.swift", "txt")
        parsingOperation = getParsingOperation()
        
        parsingOperation.main()
        
        self.measureBlock {
            self.testInsertion("Tests", location: 239, expectedRange: NSRange(location: 230, length: 24))
            
            self.testDeletion(NSRange(location: 239, length: 5), expectedRange: NSRange(location: 230, length: 19))
        }
    }
    
    func testPerformanceEdgeCases() {
        input = fixture("swifttest.swift", "txt")
        parsingOperation = getParsingOperation()
        
        parsingOperation.main()
        
        self.measureBlock {
            self.testDeletion(NSRange(location: 139, length: 1), expectedRange: NSRange(location: 139, length: 22))

            self.testInsertion("/", location: 139, expectedRange: NSRange(location: 139, length: 23))
        }
    }
    
    
    // MARK: - Helpers
    
    private func getParsingOperation() -> AttributedParsingOperation {
        return AttributedParsingOperation(string: input, language: language, theme: theme) { (results: [(range: NSRange, attributes: Attributes?)]) in
            for result in results {
                if self.totalRange == nil {
                    self.totalRange = result.range
                } else {
                    self.totalRange = NSUnionRange(self.totalRange!, result.range)
                }
            }
        }
    }
    
    private func testInsertion(string: String, location: Int, expectedRange expected: NSRange) {
        input = stringByReplacingRange(NSRange(location: location, length: 0), inString: input, withString: string)
        parsingOperation = AttributedParsingOperation(string: input, previousOperation: parsingOperation, changeIsInsertion: true, changedRange: NSRange(location: location, length: (string as NSString).length))
        
        totalRange = nil
        parsingOperation.main()
        XCTAssertEqual(totalRange!, expected)
    }
    
    private func testDeletion(range: NSRange, expectedRange expected: NSRange) {
        input = stringByReplacingRange(range, inString: input, withString: "")
        parsingOperation = AttributedParsingOperation(string: input, previousOperation: parsingOperation, changeIsInsertion: false, changedRange: range)
        
        totalRange = nil
        parsingOperation.main()
        XCTAssertEqual(totalRange, expected)
    }
}
