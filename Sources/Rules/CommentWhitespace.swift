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

/// At least two spaces before, and exactly one space after the `//` that begins a line comment.
///
/// Lint: If an invalid number of spaces appear before or after a comment, a lint error is
///       raised.
///
/// Format: All comments will have at least 2 spaces before, and a single space after, the `//`.
///
/// - SeeAlso: https://google.github.io/swift#horizontal-whitespace
public final class CommentWhitespace: SyntaxFormatRule {
  public override func visit (_ token: TokenSyntax) -> Syntax {
    var pieces = [TriviaPiece]()
    var validToken = token
    var needsWhitespaceFix = false

    guard let nextToken = token.nextToken else {
      // In the case there is a line comment at the end of the file, it ensures
      // that the line comment has a single space after the `//`.
      pieces = checksSpacesAfterLineComment(isInvalid: &needsWhitespaceFix, token: token)
      return needsWhitespaceFix ? token.withLeadingTrivia(Trivia.init(pieces: pieces)) : token
    }

    // Ensures the line comment has at least 2 spaces before the `//`.
    if hasInlineLineComment(trivia: nextToken.leadingTrivia) {
      let numSpaces = token.trailingTrivia.numberOfSpaces
      if numSpaces < 2 {
        needsWhitespaceFix = true
        let addSpaces = 2 - numSpaces
        diagnose(.addSpacesBeforeLineComment(count: addSpaces), on:token)
        validToken = token.withTrailingTrivia(token.trailingTrivia.appending(.spaces(addSpaces)))
      }
    }

    pieces = checksSpacesAfterLineComment(isInvalid: &needsWhitespaceFix, token: token)
    return needsWhitespaceFix ? validToken.withLeadingTrivia(Trivia.init(pieces: pieces)) : token
  }

  /// Returns a boolean indicating if the given trivia contains
  /// a line comment inline with code.
  private func hasInlineLineComment (trivia: Trivia) -> Bool {
    // Comments are inline unless the trivia begins with a
    // with a newline.
    if let firstPiece = trivia.reversed().last {
      if case .newlines(_) = firstPiece {
        return false
      }
    }
    for piece in trivia {
      if case .lineComment(_) = piece {
        return true
      }
    }
    return false
  }

  /// Ensures the line comment has exactly one space after the `//`.
  private func checksSpacesAfterLineComment(isInvalid: inout Bool, token: TokenSyntax) -> [TriviaPiece] {
    var pieces = [TriviaPiece]()

    for piece in token.leadingTrivia {
      // Checks if the line comment has exactly one space after the `//`,
      // if it doesn't it removes or add an space, depending on what the
      // comment needs in order to follow the right format.
      if case .lineComment(let text) = piece,
         let formatText = formatLineComment(textLineComment: text, token: token) {
        isInvalid = true
        pieces.append(TriviaPiece.lineComment(formatText))
      }
      else {
        pieces.append(piece)
      }
    }
    return pieces
  }

  /// Given a string with the text of a line comment, it ensures there
  /// is exactly one space after the `//`. If the string doesn't follow
  /// this rule a new string is returned with the right format.
  private func formatLineComment (textLineComment: String, token: TokenSyntax) -> String? {
    let text = textLineComment.dropFirst(2)
    if text.first != " " {
      diagnose(.addSpaceAfterLineComment, on: token)
      return "// " + text.trimmingCharacters(in: .whitespaces)
    }
    else if text.dropFirst(1).first == " " {
      diagnose(.removeSpacesAfterLineComment, on: token)
      return "// " + text.trimmingCharacters(in: .whitespaces)
    }
    return nil
  }
}

extension Diagnostic.Message {
  static func addSpacesBeforeLineComment(count: Int) -> Diagnostic.Message {
    let ending = count == 1 ? "" : "s"
    return Diagnostic.Message(.warning, "add \(count) space\(ending) before the //")
  }

  static let addSpaceAfterLineComment =
    Diagnostic.Message(.warning, "add one space after `//`")
  static let removeSpacesAfterLineComment =
    Diagnostic.Message(.warning, "remove excess of spaces after the `//`")
}
