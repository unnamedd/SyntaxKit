//
//  LanguageTests.swift
//  SyntaxKit
//
//  Created by Sam Soffes on 9/18/14.
//  Copyright © 2014-2015 Sam Soffes. All rights reserved.
//

import XCTest
@testable import SyntaxKit

class LanguageTests: XCTestCase {
    
    // MARK: - Properties
    
    let yaml = language("YAML")
    
    
    // MARK: - Tests
    
    func testLoading() {
        XCTAssertEqual("B0C44228-4F1F-11DA-AFF2-000A95AF0064", yaml.UUID)
        XCTAssertEqual("YAML", yaml.name)
        XCTAssertEqual("source.yaml", yaml.scopeName)
        
        XCTAssertEqual("meta.embedded.line.ruby", yaml.pattern.subpatterns[0].name)
        XCTAssertEqual("punctuation.definition.embedded.begin.ruby", yaml.pattern.subpatterns[0].beginCaptures?[0]?.name)
        XCTAssertEqual("punctuation.definition.embedded.end.ruby", yaml.pattern.subpatterns[0].endCaptures?[0]?.name)
        XCTAssertEqual("punctuation.definition.comment.ruby", yaml.pattern.subpatterns[0].subpatterns[0].captures?[1]?.name)
        XCTAssertEqual("string.unquoted.block.yaml", yaml.pattern.subpatterns[1].name)
        XCTAssertEqual("punctuation.definition.entry.yaml", yaml.pattern.subpatterns[1].beginCaptures?[2]?.name)
        XCTAssertEqual("punctuation.separator.key-value.yaml", yaml.pattern.subpatterns[1].beginCaptures?[5]?.name)
        XCTAssertEqual("constant.numeric.yaml", yaml.pattern.subpatterns[2].name)
        
        let pattern = yaml.pattern.subpatterns[3]
        XCTAssertEqual("string.unquoted.yaml", pattern.name)
        XCTAssertEqual("punctuation.definition.entry.yaml", pattern.captures?[1]?.name)
    }
}
