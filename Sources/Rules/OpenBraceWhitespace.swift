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

/// Enforces whitespace for opening braces.
///
/// Unless required by line wrapping, open braces appear on the same line as the declaration they
/// begin, with one space before them.
///
/// Lint: If a line break appears before an open brace, unless required by line wrapping, a lint
///       error is raised.
///       If a line break does not appear after an open brace, except when allowed by One Statement
///       Per Line or before a closure signature, a lint error is raised.
///
/// Format: Unless required by line wrapping, line breaks before opening braces will be removed, and
///         appropriate spacing will be inserted.
///
/// - SeeAlso: https://google.github.io/swift#braces
public final class OpenBraceWhitespace: SyntaxFormatRule {
  public override func visit(_ token: TokenSyntax) -> Syntax {
    if token.tokenKind == .leftBrace, token.leadingTrivia.containsNewlines {
      diagnose(.noLineBreakBeforeOpenBrace, on: token)
      return token.withLeadingTrivia(
        token.leadingTrivia.withoutSpaces().withoutNewlines())
    }

    if let prev = token.previousToken,
       prev.tokenKind == .leftBrace,
       !token.leadingTrivia.containsNewlines,
       !isInAllowedSingleLineContainer(prev) {
      diagnose(.lineBreakRequiredAfterOpenBrace, on: prev)
      return token.withOneLeadingNewline()
    }

    if let next = token.nextToken, next.tokenKind == .leftBrace {
      let spaceCount = token.trailingTrivia.numberOfSpaces
      if spaceCount < 1 {
        diagnose(.notEnoughSpacesBeforeOpenBrace, on: next)
      } else if spaceCount > 1 {
        diagnose(.tooManySpacesBeforeOpenBrace, on: next)
      } else {
        return token
      }
      return token.withOneTrailingSpace()
    }
    return token
  }
}

extension Diagnostic.Message {
  static let lineBreakRequiredAfterOpenBrace =
    Diagnostic.Message(.warning, "insert a newline after this '{'")
  static let notEnoughSpacesBeforeOpenBrace =
    Diagnostic.Message(.warning, "insert a space before this '{'")
  static let tooManySpacesBeforeOpenBrace =
    Diagnostic.Message(.warning, "remove extra spaces before this '{'")
  static let noLineBreakBeforeOpenBrace =
    Diagnostic.Message(.warning, "remove newline before this '{'")
}
