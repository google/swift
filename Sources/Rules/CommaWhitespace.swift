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

/// Enforces restrictions on whitespace before and after commas.
///
/// Exactly zero spaces must appear before each comma, and exactly one space after, if not at the
/// end of a line.
///
/// Lint: If an invalid number of spaces appear before or after a comma, a lint error is
///       raised.
///
/// Format: All commas will have no spaces before, and a single space after.
///
/// - SeeAlso: https://google.github.io/swift#horizontal-whitespace
public final class CommaWhitespace: SyntaxFormatRule {
  public override func visit(_ token: TokenSyntax) -> Syntax {
    guard let next = token.nextToken else { return token }

    // Commas own their trailing spaces, so ensure it only has 1 if there's
    // another token on the same line.
    if token.tokenKind == .comma && !next.leadingTrivia.containsNewlines {
      let numSpaces = token.trailingTrivia.numberOfSpaces
      if numSpaces > 1 {
        diagnose(.removeSpacesAfterComma(count: numSpaces - 1), on: token)
      }
      else if numSpaces == 0 {
        diagnose(.addSpaceAfterComma, on: token)
      }
      return token.withOneTrailingSpace()
    }

    // Otherwise, comma-adjacent tokens should have 0 spaces after.
    if next.tokenKind == .comma && token.trailingTrivia.containsSpaces {
      diagnose(.noSpacesBeforeComma, on: next)
      return token.withTrailingTrivia(token.trailingTrivia.withoutSpaces())
    }
    return token
  }
}

extension Diagnostic.Message {
  static func removeSpacesAfterComma(count: Int) -> Diagnostic.Message {
    let ending = count == 1 ? "" : "s"
    return Diagnostic.Message(.warning, "remove \(count) space\(ending) after ','")
  }

  static let addSpaceAfterComma =
    Diagnostic.Message(.warning, "add one space after ','")
  static let noSpacesBeforeComma =
    Diagnostic.Message(.warning, "remove spaces before ','")
}
