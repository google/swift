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

/// `for` loops that consist of a single `if` statement must use `where` clauses instead.
///
/// Lint: `for` loops that consist of a single `if` statement yield a lint error.
///
/// Format: `for` loops that consist of a single `if` statement have the conditional of that
///         statement factored out to a `where` clause.
///
/// - SeeAlso: https://google.github.io/swift#for-where-loops
public final class UseWhereClausesInForLoops: SyntaxFormatRule {

  public override func visit(_ node: ForInStmtSyntax) -> StmtSyntax {
    // Extract IfStmt node if it's the only node in the function's body.
    guard !node.body.statements.isEmpty else { return node }
    let stmt = node.body.statements.first!

    // Ignore for-loops with a `where` clause already.
    // FIXME: Create an `&&` expression with both conditions?
    guard node.whereClause == nil else { return node }

    // Match:
    //  - If the for loop has 1 statement, and it is an IfStmt, with a single
    //    condition.
    //  - If the for loop has 1 or more statement, and the first is a GuardStmt
    //    with a single condition whose body is just `continue`.
    switch stmt.item {
    case let ifStmt as IfStmtSyntax
      where ifStmt.conditions.count == 1 &&
            node.body.statements.count == 1:
      // Extract the condition of the IfStmt.
      let conditionElement = ifStmt.conditions.first!
      guard let condition = conditionElement.condition as? ExprSyntax else {
        return node
      }
      diagnose(.useWhereInsteadOfIf, on: ifStmt)
      return updateWithWhereCondition(
        node: node,
        condition: condition,
        statements: ifStmt.body.statements
      )
    case let guardStmt as GuardStmtSyntax
      where guardStmt.conditions.count == 1 &&
            guardStmt.body.statements.count == 1 &&
            guardStmt.body.statements.first!.item is ContinueStmtSyntax:
      // Extract the condition of the GuardStmt.
      let conditionElement = guardStmt.conditions.first!
      guard let condition = conditionElement.condition as? ExprSyntax else {
        return node
      }
      diagnose(.useWhereInsteadOfGuard, on: guardStmt)
      return updateWithWhereCondition(
        node: node,
        condition: condition,
        statements: node.body.statements.removingFirst()
      )
    default:
      return node
    }
  }
}

private func updateWithWhereCondition(
  node: ForInStmtSyntax,
  condition: ExprSyntax,
  statements: CodeBlockItemListSyntax
) -> ForInStmtSyntax {
  // Construct a new `where` clause with the condition.
  let lastToken = node.sequenceExpr.lastToken
  var whereLeadingTrivia = Trivia()
  if lastToken?.trailingTrivia.containsSpaces == false {
    whereLeadingTrivia = .spaces(1)
  }
  let whereKeyword = SyntaxFactory.makeWhereKeyword(
    leadingTrivia: whereLeadingTrivia,
    trailingTrivia: .spaces(1)
  )
  let whereClause = SyntaxFactory.makeWhereClause(
    whereKeyword: whereKeyword,
    guardResult: condition
  )

  // Replace the where clause and extract the body from the IfStmt.
  let newBody = node.body.withStatements(statements)
  return node.withWhereClause(whereClause)
             .withBody(newBody)
}

extension Diagnostic.Message {
  static let useWhereInsteadOfIf = Diagnostic.Message(
    .warning,
    "replace this 'if' statement with a 'where' clause"
  )
  static let useWhereInsteadOfGuard = Diagnostic.Message(
    .warning,
    "replace this 'guard' statement with a 'where' clause"
  )
}
