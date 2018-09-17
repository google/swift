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

/// A single space is required between an expression and a brace on the same line.
///
/// Lint: If an expression appears on the same line as a brace with invalid spaces between
///       them, a lint error is raised.
///
/// Format: A single space will be inserted between braces and same-line expressions.
///
/// - SeeAlso: https://google.github.io/swift#horizontal-whitespace
public final class OneSpaceInsideBraces: SyntaxFormatRule {

  public override func visit(_ token: TokenSyntax) -> Syntax {
    
    guard let next = token.nextToken else { return token }
    guard !next.leadingTrivia.containsNewlines else { return token }
    
    let trailingSpaces = token.trailingTrivia.numberOfSpaces
    guard trailingSpaces != 1 else { return token }

    // Insert single space between open brace and next token
    if token.tokenKind == .leftBrace {
      diagnose(trailingSpaces > 1 ? .removeSpaceAfterOpenBrace : .insertSpaceAfterOpenBrace,
               on: token)
      return token.withTrailingTrivia(next.tokenKind == .rightBrace ? [] : .spaces(1))
    // Insert single space between token and close brace
    } else if next.tokenKind == .rightBrace {
      diagnose(trailingSpaces > 1 ? .removeSpaceBeforeCloseBrace : .insertSpaceBeforeCloseBrace,
               on: next)
      return token.withTrailingTrivia(.spaces(1))
    }
    return token
  }
}

extension Diagnostic.Message {
  static let removeSpaceAfterOpenBrace =
    Diagnostic.Message(.warning, "remove extra spaces after this '{'")
  static let insertSpaceAfterOpenBrace =
    Diagnostic.Message(.warning, "insert a space after this '{'")
  static let removeSpaceBeforeCloseBrace =
    Diagnostic.Message(.warning, "remove extra spaces before this '}'")
  static let insertSpaceBeforeCloseBrace =
    Diagnostic.Message(.warning, "insert a space before this '}'")
}
