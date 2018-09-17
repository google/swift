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

/// Enforces restrictions on whitespace before and after colons.
///
/// Exactly zero spaces must appear before each colon, and exactly one space after, if not at the
/// end of a line.
///
/// Lint: If an invalid number of spaces appear before or after a colon, a lint error is
///       raised.
///
/// Format: All colons will have no spaces before, and a single space after.
///
/// - SeeAlso: https://google.github.io/swift#horizontal-whitespace
public final class ColonWhitespace: SyntaxFormatRule {
  public override func visit(_ token: TokenSyntax) -> Syntax {
    guard let next = token.nextToken else { return token }

    if token.tokenKind == .colon,
       token.containingExprStmtOrDecl is DictionaryExprSyntax,
       next.tokenKind == .rightSquareBracket,
       token.trailingTrivia.numberOfSpaces > 0 {
      diagnose(.noSpacesAfterColon, on: token)
      return token.withoutTrailingTrivia()
    }

    /// Colons own their trailing spaces, so ensure it only has 1 if there's
    /// another token on the same line.
    if token.tokenKind == .colon,
       !next.leadingTrivia.containsNewlines {
      let numSpaces = token.trailingTrivia.numberOfSpaces
      if numSpaces > 1 {
        diagnose(.removeSpacesAfterColon(count: numSpaces - 1), on: token)
      }
      if numSpaces == 0 {
        diagnose(.addSpaceAfterColon, on: token)
      }
      return token.withOneTrailingSpace()
    }

    /// Otherwise, colon-adjacent tokens should have 0 spaces after.
    if next.tokenKind == .colon, token.trailingTrivia.containsSpaces,
      !(next.containingExprStmtOrDecl is TernaryExprSyntax) {
      diagnose(.noSpacesBeforeColon, on: next)
      return token.withTrailingTrivia(token.trailingTrivia.withoutSpaces())
    }
    return token
  }
}

extension Diagnostic.Message {
  static func removeSpacesAfterColon(count: Int) -> Diagnostic.Message {
    let ending = count == 1 ? "" : "s"
    return Diagnostic.Message(.warning, "remove \(count) space\(ending) after ':'")
  }

  static let addSpaceAfterColon =
    Diagnostic.Message(.warning, "add one space after ':'")
  static let noSpacesBeforeColon =
    Diagnostic.Message(.warning, "remove spaces before ':'")
  static let noSpacesAfterColon =
    Diagnostic.Message(.warning, "remove spaces after ':'")
}
