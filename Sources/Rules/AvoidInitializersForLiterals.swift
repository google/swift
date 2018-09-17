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

fileprivate let intSizes = ["", "8", "16", "32", "64"]
fileprivate let knownIntTypes = Set(intSizes.map { "Int\($0)" } + intSizes.map { "UInt\($0)" })

/// Avoid using initializer-style casts for literals.
///
/// Using `UInt8(256)` will not error for overflow, leading to a runtime crash. Convert these to
/// `256 as UInt8`, to move the error from runtime to compile time.
///
/// Lint: If an initializer-style cast is used on a built-in type known to be expressible by
///       that kind of literal type, a lint error is raised.
///
/// Format: Initializer-style casts between known built-in types will be converted to standard
///         casts.
///
/// - SeeAlso: https://google.github.io/swift#numeric-and-string-literals
public final class AvoidInitializersForLiterals: SyntaxFormatRule {
  public override func visit(_ node: FunctionCallExprSyntax) -> ExprSyntax {
    // Ensure we're calling a known Integer initializer.
    guard let callee = node.calledExpression as? IdentifierExprSyntax else {
      // Ensure we properly visit the children of this node, in case we have other function calls
      // as parameters to this one.
      return super.visit(node)
    }

    let typeName = callee.identifier.text

    guard let literal = extractLiteral(node, typeName) else {
      return super.visit(node)
    }

    diagnose(.avoidInitializerStyleCast, on: callee) {
      $0.highlight(callee.sourceRange(in: self.context.fileURL))
    }

    // Construct an 'as' cast, converting `X(y)` to `y as X`.
    let asExpr = AsExprSyntax {
      $0.useAsTok(SyntaxFactory.makeAsKeyword(
        trailingTrivia: .spaces(1)
      ))
      $0.useTypeName(
        SyntaxFactory.makeSimpleTypeIdentifier(
          name: callee.identifier,
          genericArgumentClause: nil
        )
      )
    }

    let newLiteral = replaceTrivia(
      on: literal,
      token: literal.firstToken,
      trailingTrivia: .spaces(1)
    ) as! ExprSyntax

    return SyntaxFactory.makeSequenceExpr(
      elements: SyntaxFactory.makeExprList([
        newLiteral,
        asExpr,
      ]))
  }
}

fileprivate func extractLiteral(_ node: FunctionCallExprSyntax, _ typeName: String) -> ExprSyntax? {
  guard let firstArg = node.argumentList.first, node.argumentList.count == 1 else {
    return nil
  }
  if knownIntTypes.contains(typeName) {
    return firstArg.expression as? IntegerLiteralExprSyntax
  }
  if typeName == "Character" {
    return firstArg.expression as? StringLiteralExprSyntax
  }
  return nil
}

extension Diagnostic.Message {
  static let avoidInitializerStyleCast =
    Diagnostic.Message(.warning, "change initializer call with literal argument to an 'as' cast")
}
