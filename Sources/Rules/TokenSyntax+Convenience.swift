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

import SwiftSyntax

extension TokenSyntax {
  /// Returns this token with only one space at the end of its trailing trivia.
  func withOneTrailingSpace() -> TokenSyntax {
    return withTrailingTrivia(trailingTrivia.withOneTrailingSpace())
  }

  /// Returns this token with only one space at the beginning of its leading
  /// trivia.
  func withOneLeadingSpace() -> TokenSyntax {
    return withLeadingTrivia(leadingTrivia.withOneLeadingSpace())
  }

  /// Returns this token with only one newline at the end of its leading trivia.
  func withOneTrailingNewline() -> TokenSyntax {
    return withTrailingTrivia(trailingTrivia.withOneTrailingNewline())
  }

  /// Returns this token with only one newline at the beginning of its leading
  /// trivia.
  func withOneLeadingNewline() -> TokenSyntax {
    return withLeadingTrivia(leadingTrivia.withOneLeadingNewline())
  }
}
