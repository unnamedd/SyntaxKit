//
//  Patterns.swift
//  SyntaxKit
//
//  Created by Alexander Hedges on 09/01/16.
//  Copyright © 2016 Sam Soffes. All rights reserved.
//

import Foundation

class Patterns {
    private var content: [Pattern]
    
    init(array: [[NSObject: AnyObject]], repository: Repository) {
        
        content = []
        for value in array {
            if let include = value["include"] as? String {
                if include.hasPrefix("#") {
                    let key = include.substringFromIndex(include.startIndex.successor())
                    if let pattern = repository[key] {
                        content.append(pattern)
                    } //else if key == self.name {
//                        let newSelf = Pattern(pattern: self, parent: nil)
//                        self.patterns.append(newSelf)
//                    }
                } else if include == "$self" {
                    // TODO: recursive stuff
                }
            } else if let pattern = Pattern(dictionary: value, repository: repository) {
                content.append(pattern)
            }
        }
    }
    
    func getContent() -> [Pattern] {
        return content
    }
}