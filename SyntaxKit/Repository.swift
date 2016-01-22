//
//  Repository.swift
//  SyntaxKit
//
//  Created by Alexander Hedges on 09/01/16.
//  Copyright © 2016 Sam Soffes. All rights reserved.
//

import Foundation

class Repository {
    private var entries: [String: Pattern]
    
    init(repo: [String: [NSObject: AnyObject]]) {
        self.entries = [:]
        for (key, value) in repo {
            if let containedRepo = value["repository"] as? [String: [NSObject: AnyObject]] {
                let newEntries = NSMutableDictionary(dictionary: self.entries)
                newEntries.addEntriesFromDictionary(Repository(repo: containedRepo).allEntries())
                self.entries = newEntries.copy() as! [String: Pattern]
            }
            if let pattern = Pattern(dictionary: value, repository: self) {
                self.entries[key] = pattern
            }
        }
        for (key, value) in repo { // now that we have all dependencies, try again
            if let pattern = Pattern(dictionary: value, repository: self) {
                self.entries[key] = pattern
            }
        }
    }
    
    func allEntries() -> [String: Pattern] {
        return entries
    }
    
    subscript(index: String) -> Pattern? {
        return entries[index]
    }
}