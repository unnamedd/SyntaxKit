//
//  ScopedStringTests.swift
//  SyntaxKit
//
//  Created by Alexander Hedges on 30/01/16.
//  Copyright © 2016 Alexander Hedges. All rights reserved.
//

import XCTest
@testable import SyntaxKit

class ScopedStringTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testScopesString() {
        var newScopedString = ScopedString(string: "Test")
        XCTAssert(newScopedString.numberOfScopes() == 1)
        XCTAssert(newScopedString.numberOfLevels() == 1)
        
        XCTAssert(newScopedString.topmostScopeAtIndex(2) == newScopedString.baseScope)
        
        let newScope1 = Scope(identifier: "bogus", range: NSRange(location: 1, length: 3), attribute: nil)
        newScopedString.addScopeAtTop(newScope1)
        XCTAssert(newScopedString.numberOfScopes() == 2)
        XCTAssert(newScopedString.numberOfLevels() == 2)
        
        XCTAssert(newScopedString.topmostScopeAtIndex(0) == newScopedString.baseScope)
        XCTAssert(newScopedString.topmostScopeAtIndex(1) == newScope1)
        XCTAssert(newScopedString.lowerScopeForScope(newScope1, AtIndex: 1) == newScopedString.baseScope)
        
        let newScope2 = Scope(identifier: "bogus2", range: NSRange(location: 2, length: 1), attribute: nil)
        newScopedString.addScopeAtTop(newScope2)
        XCTAssert(newScopedString.numberOfScopes() == 3)
        XCTAssert(newScopedString.numberOfLevels() == 3)
        
        XCTAssert(newScopedString.topmostScopeAtIndex(1) == newScope1)
        XCTAssert(newScopedString.topmostScopeAtIndex(2) == newScope2)
        
        XCTAssertFalse(newScopedString.numberOfScopes() == 1)
        
        newScopedString.deleteCharactersInRange(NSRange(location: 2, length: 1))
        XCTAssert(newScopedString.underlyingString == "Tet")
        XCTAssert(newScopedString.numberOfScopes() == 2)
        XCTAssert(newScopedString.numberOfLevels() == 2)
        
        XCTAssert(newScopedString.topmostScopeAtIndex(1).range == NSRange(location: 1, length: 2))
        
        newScopedString.insertString("ssssss", atIndex: 2)
        XCTAssert(newScopedString.underlyingString == "Tesssssst")
        XCTAssert(newScopedString.numberOfScopes() == 2)
        
        let newScope3 = Scope(identifier: "zeroLengthScope1", range: NSRange(location: 0, length: 0), attribute: nil)
        newScopedString.addScopeAtTop(newScope3)
        let newScope4 = Scope(identifier: "zeroLengthScope2", range: NSRange(location: 3, length: 0), attribute: nil)
        newScopedString.addScopeAtTop(newScope4)
        XCTAssert(newScopedString.numberOfScopes() == 4)
        XCTAssert(newScopedString.topmostScopeAtIndex(0).patternIdentifier == "zeroLengthScope1")
        
        newScopedString.removeScopesInRange(NSRange(location: 0, length: 1))
        XCTAssert(newScopedString.numberOfScopes() == 3)
        
        XCTAssert(newScopedString.topmostScopeAtIndex(2).range == NSRange(location: 1, length: 8))
    }
    
    func testRangeExtension() {
        var someRange = NSRange(location: 0, length: 24)
        XCTAssertFalse(someRange.isEmpty())
        
        someRange = NSRange(location: 49, length: 0)
        XCTAssertTrue(someRange.isEmpty())
        
        someRange = NSRange(location: 4, length: 2)
        XCTAssertTrue(someRange.containsIndex(4))
        XCTAssertFalse(someRange.containsIndex(1))
        XCTAssertFalse(someRange.containsIndex(23))
        
        someRange = NSRange(location: 0, length: 24)
        someRange.removeIndexesFromRange(NSRange(location: 2, length: 4))
        XCTAssertEqual(someRange, NSRange(location: 0, length: 20))
        
        someRange = NSRange(location: 20, length: 40)
        someRange.removeIndexesFromRange(NSRange(location: 4, length: 12))
        XCTAssertEqual(someRange, NSRange(location: 8, length: 40))
        
        someRange = NSRange(location: 23, length: 11)
        someRange.removeIndexesFromRange(NSRange(location: 20, length: 5))
        XCTAssertEqual(someRange, NSRange(location: 20, length: 9))
        
        someRange = NSRange(location: 10, length: 14)
        someRange.removeIndexesFromRange(NSRange(location: 5, length: 40))
        XCTAssertTrue(someRange.isEmpty())
        
        someRange = NSRange(location: 23, length: 11)
        someRange.insertIndexesFromRange(NSRange(location: 20, length: 5))
        XCTAssertEqual(someRange, NSRange(location: 28, length: 11))
        
        someRange = NSRange(location: 14, length: 2)
        someRange.insertIndexesFromRange(NSRange(location: 15, length: 7))
        XCTAssertEqual(someRange, NSRange(location: 14, length: 9))
        
        someRange = NSRange(location: 26, length: 36)
        someRange.insertIndexesFromRange(NSRange(location: 62, length: 5))
        XCTAssertEqual(someRange, NSRange(location: 26, length: 36))
    }
}
