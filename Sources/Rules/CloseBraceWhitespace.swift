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

// TODO(abl): "right brace" to be consistent with SwiftSyntax?
/// Enforce whitespace for close braces.
///
/// Lint: If a close brace does not have a line break before it, except as covered by One Statement
///       Per Line, a lint error will be raised.
///
/// Format: Line breaks will be inserted for all non-conforming close braces.
///
/// - SeeAlso: https://google.github.io/swift#braces
public final class CloseBraceWhitespace: SyntaxFormatRule {
  public override func visit(_ token: TokenSyntax) -> Syntax {
    guard token.tokenKind == .rightBrace else { return token }
    if isInAllowedSingleLineContainer(token) { return token }
    if token.leadingTrivia.containsNewlines { return token }

    diagnose(.lineBreakRequiredBeforeCloseBrace, on: token)
    return token.withOneLeadingNewline()
  }
}

/// Returns `true` if the containing syntax node that is allowed to be a
/// single-line braced node (currently closures and getters/setters), if the
/// node has only one statement.
func isInAllowedSingleLineContainer(_ token: TokenSyntax) -> Bool {
  if token.parent is AccessorBlockSyntax { return true }
  guard let container = token.containingExprStmtOrDecl else { return false }
  if let stmtContainer = container as? WithStatementsSyntax {
    guard stmtContainer.statements.count <= 1,
          stmtContainer is ClosureExprSyntax ||
          stmtContainer is AccessorDeclSyntax else {
      return false
    }
    return true
  } else if let block = token.parent as? CodeBlockSyntax {
    return block.statements.count <= 1
  }
  return false
}

extension Diagnostic.Message {
  static let lineBreakRequiredBeforeCloseBrace =
    Diagnostic.Message(.warning, "insert a newline before this '}'")
}

