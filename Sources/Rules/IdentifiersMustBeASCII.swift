//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Formatter open source project.
//
// Copyright (c) 2018 Apple Inc. and the Swift Formatter project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Swift Formatter project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import Core
import Foundation
import SwiftSyntax

/// All identifiers must be ASCII.
///
/// Lint: If an identifier contains non-ASCII characters, a lint error is raised.
///
/// - SeeAlso: https://google.github.io/swift#identifiers
public final class IdentifiersMustBeASCII: SyntaxLintRule {
  public override func visit(_ node: IdentifierPatternSyntax) {
    let identifier = node.identifier.text
    let invalidCharacters = identifier.unicodeScalars.filter { !$0.isASCII }.map { $0.description }
    
    if !invalidCharacters.isEmpty {
      diagnose(.nonASCIICharsNotAllowed(invalidCharacters, identifier), on: node)
    }
  }
}

extension Diagnostic.Message {
  static func nonASCIICharsNotAllowed(_ invalidCharacters: [String], _ identifierName: String) -> Diagnostic.Message {
    return .init(.warning, "The identifier '\(identifierName)' contains the following non-ASCII characters: \(invalidCharacters.joined(separator: ", "))")
  }
}
