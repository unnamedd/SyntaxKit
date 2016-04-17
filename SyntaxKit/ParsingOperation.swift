//
//  ParsingOperation.swift
//  SyntaxKit
//
//  Created by Alexander Hedges on 17/04/16.
//  Copyright © 2016 Alexander Hedges. All rights reserved.
//

public class ParsingOperation: NSOperation {
    
    private let parser: AttributedParser
    
    public init(language: Language, theme: Theme) {
        parser = AttributedParser(language: language, theme: theme)
    }
    
    public override func main() {
//        parser.parse("test", match: nil)
    }
    
}
