//
//  Language.swift
//  SyntaxKit
//
//  Created by Sam Soffes on 9/18/14.
//  Copyright © 2014-2015 Sam Soffes. All rights reserved.
//

import Foundation

public struct Language {

	// MARK: - Properties

	public let UUID: String
	public let name: String
	public let scopeName: String
	let patterns: Patterns


	// MARK: - Initializers

	public init?(dictionary: [NSObject: AnyObject]) {
		guard let UUID = dictionary["uuid"] as? String,
			name = dictionary["name"] as? String,
			scopeName = dictionary["scopeName"] as? String
			else { return nil }

		self.UUID = UUID
		self.name = name
		self.scopeName = scopeName

        let repository: Repository
        if let repo = dictionary["repository"] as? [String: [NSObject: AnyObject]] {
            repository = Repository(repo: repo)
        } else {
            repository = Repository(repo: [:])
        }
        
        if let array = dictionary["patterns"] as? [[NSObject: AnyObject]] {
			self.patterns = Patterns(array: array, repository: repository)
        } else {
            self.patterns = Patterns(array: [], repository: repository)
        }
	}
}
