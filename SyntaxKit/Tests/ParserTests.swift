//
//  ParserTests.swift
//  SyntaxKit
//
//  Created by Sam Soffes on 6/15/15.
//  Copyright © 2015 Sam Soffes. All rights reserved.
//

import XCTest
import SyntaxKit

class ParserTests: XCTestCase {
    
    // MARK: - Properties
    
    let parser = Parser(language: language("YAML"))
    
    
    // MARK: - Tests
    
    func testParsingBeginEnd() {
        var stringQuoted: NSRange?
        var punctuationBegin: NSRange?
        var punctuationEnd: NSRange?
        
        parser.parse("title: \"Hello World\"\n") { (result: (scope: String, range: NSRange)) in
                if stringQuoted == nil && result.scope.hasPrefix("string.quoted.double") {
                    stringQuoted = result.range
                }
                
                if punctuationBegin == nil && result.scope.hasPrefix("punctuation.definition.string.begin") {
                    punctuationBegin = result.range
                }
                
                if punctuationEnd == nil && result.scope.hasPrefix("punctuation.definition.string.end") {
                    punctuationEnd = result.range
                }
        }
        
        XCTAssertEqual(NSMakeRange(7, 13), stringQuoted)
        XCTAssertEqual(NSMakeRange(7, 1), punctuationBegin)
        XCTAssertEqual(NSMakeRange(19, 1), punctuationEnd)
    }
    
    func testParsingBeginEndCrap() {
        var stringQuoted: NSRange?
        
        parser.parse("title: Hello World\ncomments: 24\nposts: \"12\"zz\n") { (result: (scope: String, range: NSRange)) in
                if stringQuoted == nil && result.scope.hasPrefix("string.quoted.double") {
                    stringQuoted = result.range
                }
        }
        
        XCTAssertEqual(NSMakeRange(39, 4), stringQuoted)
    }
    
    func testParsingGarbage() {
        parser.parse("") { _ in }
        parser.parse("ainod adlkf ac\nv a;skcja\nsd flaksdfj [awiefasdvxzc\\vzxcx c\n\n\nx \ncvas\ndv\nas \ndf as]pkdfa \nsd\nfa sdos[a \n\n a\ns cvsa\ncd\n a \ncd\n \n\n\n asdcp[vk sa\n\ndd'; \nssv[ das \n\n\nlkjs") { _ in }
    }
    
    func testRuby() {
        let parser = Parser(language: language("Ruby"))
        let input = fixture("test.rb", "txt")
        parser.parse(input, match: { _ in return })
    }
}
