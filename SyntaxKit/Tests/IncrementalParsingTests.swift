//
//  IncrementalParsingTests.swift
//  SyntaxKit
//
//  Created by Alexander Hedges on 27/01/16.
//  Copyright © 2016 Sam Soffes. All rights reserved.
//

import XCTest
import SyntaxKit

class IncrementalParsingTests: XCTestCase {
    
    let parser = Parser(language: language("Swift"))

    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }

    func testExample() {
        let input = fixture("swifttest.swift", "txt")
        
        var rangeToParse = parser.outdatedRangeForChangeInString(input, changeIsInsertion: true, changedRange: NSRange(location: 0, length: 5))
        XCTAssertEqual(rangeToParse, nil)
        
        parser.parse(input) { _, _ in return }
        
        var newInput = stringByReplacingRange(NSRange(location: 20, length: 0), inString: input, withString: " ")
        rangeToParse = parser.outdatedRangeForChangeInString(newInput, changeIsInsertion: true, changedRange: NSRange(location: 20, length: 1))
        XCTAssertEqual(rangeToParse, NSRange(location: 5, length: 17))
        
        newInput = stringByReplacingRange(NSRange(location: 162, length: 0), inString: input, withString: "i")
        rangeToParse = parser.outdatedRangeForChangeInString(newInput, changeIsInsertion: true, changedRange: NSRange(location: 162, length: 1))
        XCTAssertEqual(rangeToParse, NSRange(location: 162, length: 2))
        
        parser.parse(newInput) { _, _ in return }
        
        newInput = stringByReplacingRange(NSRange(location: 162, length: 1), inString: newInput, withString: "")
        rangeToParse = parser.outdatedRangeForChangeInString(newInput, changeIsInsertion: false, changedRange: NSRange(location: 162, length: 1))
        XCTAssertEqual(rangeToParse, NSRange(location: 162, length: 1))
        
        parser.parse(input) { _, _ in return }
        
        newInput = stringByReplacingRange(NSRange(location: 160, length: 0), inString: input, withString: "756")
        rangeToParse = parser.outdatedRangeForChangeInString(newInput, changeIsInsertion: true, changedRange: NSRange(location: 160, length: 3))
        XCTAssertEqual(rangeToParse, NSRange(location: 142, length: 23))
        
        newInput = stringByReplacingRange(NSRange(location: 159, length: 0), inString: input, withString: "756")
        rangeToParse = parser.outdatedRangeForChangeInString(newInput, changeIsInsertion: true, changedRange: NSRange(location: 159, length: 3))
        XCTAssertEqual(rangeToParse, NSRange(location: 142, length: 23))
    }

    func testPerformanceInScope() {
        let input = fixture("swifttest.swift", "txt")
        self.parser.parse(input) { _, _ in return }
        
        self.measureBlock {
            let newInput = stringByReplacingRange(NSRange(location: 239, length: 0), inString: input, withString: "Tests")
            var rangeToParse = self.parser.outdatedRangeForChangeInString(newInput, changeIsInsertion: true, changedRange: NSRange(location: 239, length: 5))
            XCTAssertEqual(rangeToParse, NSRange(location: 230, length: 24))
            
            self.parser.parse(newInput, inRange: rangeToParse) { _, _ in return }
            
            rangeToParse = self.parser.outdatedRangeForChangeInString(input, changeIsInsertion: false, changedRange: NSRange(location: 239, length: 5))
            XCTAssertEqual(rangeToParse, NSRange(location: 230, length: 19))
            
            self.parser.parse(input, inRange: rangeToParse) { _, _ in return }
        }
    }
    
    func testPerformanceEdgeCases() {
        let input = fixture("swifttest.swift", "txt")
        self.parser.parse(input) { _, _ in return }
        
        self.measureBlock {
            let newInput = stringByReplacingRange(NSRange(location: 139, length: 1), inString: input, withString: "")
            var rangeToParse = self.parser.outdatedRangeForChangeInString(newInput, changeIsInsertion: false, changedRange: NSRange(location: 139, length: 1))
            XCTAssertEqual(rangeToParse, NSRange(location: 139, length: 22))
            
            self.parser.parse(newInput, inRange: rangeToParse) { _, _ in return }
            
            rangeToParse = self.parser.outdatedRangeForChangeInString(input, changeIsInsertion: true, changedRange: NSRange(location: 139, length: 1))
            XCTAssertEqual(rangeToParse, NSRange(location: 139, length: 4))
            
            self.parser.parse(input, inRange: rangeToParse) { _, _ in return }
        } 
    } 
}
