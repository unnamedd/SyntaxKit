//
//  ScopedStringTests.swift
//  SyntaxKit
//
//  Created by Alexander Hedges on 30/01/16.
//  Copyright © 2016 Sam Soffes. All rights reserved.
//

import XCTest
@testable
import SyntaxKit

class ScopedStringTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }

    func testScopesString() {
        let newScopedString = ScopedString(string: "Test")
        XCTAssert(newScopedString.numberOfScopes() == 1)
        XCTAssert(newScopedString.numberOfLevels() == 1)
        
        XCTAssert(newScopedString.topLevelScopeAtIndex(2, onlyBodyResults: true) == newScopedString.baseScope)
        
        let newScope1 = Scope(name: "bogus", range: HeadedRange(location: 1, headerLength: 1, bodyLength: 2), attribute: nil)
        newScopedString.addScopeAtTopWithName(newScope1.name, inRange: newScope1.range)
        XCTAssert(newScopedString.numberOfScopes() == 2)
        XCTAssert(newScopedString.numberOfLevels() == 2)
        
        XCTAssert(newScopedString.topLevelScopeAtIndex(0, onlyBodyResults: true) == newScopedString.baseScope)
        XCTAssert(newScopedString.topLevelScopeAtIndex(1, onlyBodyResults: true) == newScopedString.baseScope)
        XCTAssert(newScopedString.topLevelScopeAtIndex(1, onlyBodyResults: false) == newScope1)
        XCTAssert(newScopedString.lowerScopeForScope(newScope1, AtIndex: 1) == newScopedString.baseScope)
        
        let newScope2 = Scope(name: "bogus2", range: HeadedRange(location: 2, headerLength: 0, bodyLength: 1), attribute: nil)
        newScopedString.addScopeAtTopWithName(newScope2.name, inRange: newScope2.range)
        XCTAssert(newScopedString.numberOfScopes() == 3)
        XCTAssert(newScopedString.numberOfLevels() == 3)
        
        XCTAssert(newScopedString.topLevelScopeAtIndex(1, onlyBodyResults: false) == newScope1)
        XCTAssert(newScopedString.topLevelScopeAtIndex(2, onlyBodyResults: false) == newScope2)
        XCTAssert(newScopedString.topLevelScopeAtIndex(3, onlyBodyResults: true) == newScope1)
        
        XCTAssertFalse(newScopedString.numberOfScopes() == 1)
        
        newScopedString.deleteCharactersInRange(NSRange(location: 2, length: 1))
        XCTAssert(newScopedString.underlyingString == "Tet")
        XCTAssert(newScopedString.numberOfScopes() == 2)
        XCTAssert(newScopedString.numberOfLevels() == 2)
        
        XCTAssert(newScopedString.topLevelScopeAtIndex(1, onlyBodyResults: false).range == HeadedRange(location: 1, headerLength: 1, bodyLength: 1))
        
        newScopedString.insertString("ssssss", atIndex: 2)
        XCTAssert(newScopedString.underlyingString == "Tesssssst")
        XCTAssert(newScopedString.numberOfScopes() == 2)
        
        XCTAssert(newScopedString.topLevelScopeAtIndex(2, onlyBodyResults: false).range == HeadedRange(location: 1, headerLength: 1, bodyLength: 7))
    }
}
