//
//  Pattern.swift
//  SyntaxKit
//
//  Created by Sam Soffes on 9/18/14.
//  Copyright © 2014-2015 Sam Soffes. All rights reserved.
//

import Foundation

final class Pattern {

    // MARK: - Properties

    let name: String?
    let match: NSRegularExpression?
    let captures: CaptureCollection?
    let begin: NSRegularExpression?
    let beginCaptures: CaptureCollection?
    let end: NSRegularExpression?
    let endCaptures: CaptureCollection?
    private weak var parent: Pattern?
    private var patterns: Patterns

    var superpattern: Pattern? {
        return parent
    }

    var subpatterns: Patterns {
        return patterns
    }

    // MARK: - Initializers

    init?(dictionary: [NSObject: AnyObject], repository: Repository, parent: Pattern? = nil) {
        self.parent = parent
        self.name = dictionary["name"] as? String

        if let matchExpr = dictionary["match"] as? String {
            self.match = try? NSRegularExpression(pattern: matchExpr, options:[.AnchorsMatchLines]) //[.CaseInsensitive]
        } else {
            self.match = nil
        }

        if let beginExpr = dictionary["begin"] as? String {
            self.begin = try? NSRegularExpression(pattern: beginExpr, options:[.AnchorsMatchLines])
        } else {
            self.begin = nil
        }

        if let endExpr = dictionary["end"] as? String {
            self.end = try? NSRegularExpression(pattern: endExpr, options:[.AnchorsMatchLines])
        } else {
            self.end = nil
        }

        if let dictionary = dictionary["beginCaptures"] as? [NSObject: AnyObject] {
            self.beginCaptures = CaptureCollection(dictionary: dictionary)
        } else {
            self.beginCaptures = nil
        }

        if let dictionary = dictionary["captures"] as? [NSObject: AnyObject] {
            self.captures = CaptureCollection(dictionary: dictionary)
        } else {
            self.captures = nil
        }

        if let dictionary = dictionary["endCaptures"] as? [NSObject: AnyObject] {
            self.endCaptures = CaptureCollection(dictionary: dictionary)
        } else {
            self.endCaptures = nil
        }

        if let array = dictionary["patterns"] as? [[NSObject: AnyObject]] {
            self.patterns = Patterns(array: array, repository: repository)
        } else {
            self.patterns = Patterns(array: [], repository: repository)
        }

        if dictionary["match"] as? String != nil && self.match == nil {
            return nil
        }

        if dictionary["begin"] as? String != nil && (self.begin == nil || self.end == nil) {
            return nil
        }
    }
}
