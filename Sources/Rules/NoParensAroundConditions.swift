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

/// Enforces rules around parentheses in conditions or matched expressions.
///
/// Parentheses are not used around any condition of an `if`, `guard`, or `while` statement, or
/// around the matched expression in a `switch` statement.
///
/// Lint: If a top-most expression in a `switch`, `if`, `guard`, or `while` statement is surrounded
///       by parentheses, and it does not include a function call with a trailing closure, a lint
///       error is raised.
///
/// Format: Parentheses around such expressions are removed, if they do not cause a parse ambiguity.
///         Specifically, parentheses are allowed if and only if the expression contains a function
///         call with a trailing closure.
///
/// - SeeAlso: https://google.github.io/swift#parentheses
public final class NoParensAroundConditions: SyntaxFormatRule {
  func extractExpr(_ tuple: TupleExprSyntax) -> ExprSyntax {
    assert(tuple.elementList.count == 1)
    let expr = tuple.elementList.first!.expression

    // If the condition is a function with a trailing closure, removing the
    // outer set of parentheses introduces a parse ambiguity.
    if let fnCall = expr as? FunctionCallExprSyntax, fnCall.trailingClosure != nil {
      return tuple
    }

    diagnose(.removeParensAroundExpression, on: expr) {
      $0.highlight(expr.sourceRange(in: self.context.fileURL))
    }

    return replaceTrivia(
      on: expr,
      token: expr.lastToken,
      leadingTrivia: tuple.leftParen.leadingTrivia,
      trailingTrivia: tuple.rightParen.trailingTrivia
    ) as! ExprSyntax
  }

  public override func visit(_ node: IfStmtSyntax) -> StmtSyntax {
    let conditions = visit(node.conditions) as! ConditionElementListSyntax
    return node.withIfKeyword(node.ifKeyword.withOneTrailingSpace())
      .withConditions(conditions)
  }

  public override func visit(_ node: ConditionElementSyntax) -> Syntax {
    guard let tup = node.condition as? TupleExprSyntax,
      tup.elementList.count == 1 else {
        return node
    }
    return node.withCondition(extractExpr(tup))
  }

  /// FIXME(hbh): Parsing for SwitchStmtSyntax is not implemented.
  public override func visit(_ node: SwitchStmtSyntax) -> StmtSyntax {
    guard let tup = node.expression as? TupleExprSyntax,
      tup.elementList.count == 1 else {
      return node
    }
    return node.withExpression(extractExpr(tup))
  }

  public override func visit(_ node: RepeatWhileStmtSyntax) -> StmtSyntax {
    guard let tup = node.condition as? TupleExprSyntax,
      tup.elementList.count == 1 else {
      return node
    }
    let newNode = node.withCondition(extractExpr(tup))
      .withWhileKeyword(node.whileKeyword.withOneTrailingSpace())
    return newNode
  }
}

extension Diagnostic.Message {
  static let removeParensAroundExpression =
    Diagnostic.Message(.warning, "remove parentheses around this expression")
}
