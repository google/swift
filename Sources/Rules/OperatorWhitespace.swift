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
 
 /// Exactly one space must appear before and after each binary operator token.
 ///
 /// Lint: If an invalid number of spaces appear before or after a binary operator, a lint error is
 ///       raised.
 ///
 /// Format: All binary operators will have a single space before and after.
 ///
 /// - SeeAlso: https://google.github.io/swift#horizontal-whitespace
 public final class OperatorWhitespace: SyntaxFormatRule {
  let rangeOperators =  ["...", "..<", ">.."]
  public override func visit(_ node: ExprListSyntax) -> Syntax {
    var expressions = [ExprSyntax]()
    var hasInvalidNumSpaces = false
    for expr in node { expressions.append(expr) }
    
    // Iterates through all the elements of the expression to find the position of
    // a binary operator and ensures that the spacing before and after are valid.
    for index in 0..<expressions.count - 1 {
      let expr = expressions[index]
      let nextExpr = expressions[index + 1]
      guard let exprToken = expr.lastToken else { continue }
      
      // Ensures all binary operators have one space before and after them, except
      // for the rangeOperators.
      if expr is BinaryOperatorExprSyntax {
        // All range operators must have zero spaces surrounding them.
        if rangeOperators.contains(exprToken.text) {
          expressions[index - 1] = expressionWithoutTrailingSpaces(
            expr: expressions[index - 1],
            invalidNumSpaces: &hasInvalidNumSpaces
          )

          expressions[index] = expressionWithoutTrailingSpaces(
            expr: expr,
            invalidNumSpaces: &hasInvalidNumSpaces
          )

          if exprToken.tokenKind == .spacedBinaryOperator(exprToken.text) &&
            nextExpr is PrefixOperatorExprSyntax {
            hasInvalidNumSpaces = true
            expressions[index + 1] = addParenthesisToElement(expressions[index + 1])
          }
        }
        else {
          expressions[index - 1] = exprWithOneTrailingSpace(
            expr: expressions[index - 1],
            invalidNumSpaces: &hasInvalidNumSpaces
          )
          expressions[index] = exprWithOneTrailingSpace(
            expr: expr,
            invalidNumSpaces: &hasInvalidNumSpaces
          )
        }
      }
    }
    return hasInvalidNumSpaces ? SyntaxFactory.makeExprList(expressions) : node
  }

  public override func visit(_ node: CompositionTypeElementListSyntax) -> Syntax {
    var elements = [CompositionTypeElementSyntax]()
    var hasInvalidNumSpaces = false
    
    for element in node {
      // Ensures that the ampersand of the composition has one space before and after it.
      if compositeHasInvalidNumberOfSpaces(element) {
        hasInvalidNumSpaces = true

        let elementWithOneTrailingSpace = replaceTrivia(
          on: element,
          token: element.ampersand!.previousToken!,
          trailingTrivia: element.ampersand!.previousToken!.trailingTrivia.withOneTrailingSpace()
        ) as! CompositionTypeElementSyntax

        let ampersandWithOneTrailingSpace = replaceTrivia(
          on: element.ampersand!,
          token: element.ampersand!,
          trailingTrivia: element.ampersand!.trailingTrivia.withOneTrailingSpace()
        ) as! TokenSyntax

        let replacedElement = SyntaxFactory.makeCompositionTypeElement(
          type: elementWithOneTrailingSpace.type,
          ampersand: ampersandWithOneTrailingSpace)

        elements.append(replacedElement)
      }
      else {
        elements.append(element)
      }
    }
    return hasInvalidNumSpaces ? SyntaxFactory.makeCompositionTypeElementList(elements) : node
  }

  /// Indicates ampersand of the given composition doesn't have one space after and before it.
  func compositeHasInvalidNumberOfSpaces(_ element: CompositionTypeElementSyntax) -> Bool {
    guard let elementAmpersand = element.ampersand else { return false }
    guard let prevToken = elementAmpersand.previousToken else { return false }
    
    switch elementAmpersand.tokenKind {
    case .unspacedBinaryOperator(elementAmpersand.text), .postfixOperator(elementAmpersand.text):
      return true
    case .spacedBinaryOperator(elementAmpersand.text):
      return elementAmpersand.trailingTrivia.numberOfSpaces > 1 ||
        prevToken.trailingTrivia.numberOfSpaces > 1 ? true : false
    default:
      return false
    }
  }

  /// Ensures that the trailing trivia of the given expression doesn't contain
  /// any spaces.
  func expressionWithoutTrailingSpaces(
    expr: ExprSyntax,
    invalidNumSpaces: inout Bool
  ) -> ExprSyntax {
    guard let exprTrailingTrivia = expr.trailingTrivia else { return expr }
    guard let exprLastToken = expr.lastToken else { return expr }
    let numSpaces = exprTrailingTrivia.numberOfSpaces

    if numSpaces > 0 {
      invalidNumSpaces = true
      let replacedExpression = replaceTrivia(
        on: expr,
        token: exprLastToken,
        trailingTrivia: exprTrailingTrivia.withoutSpaces()
        ) as! ExprSyntax

      diagnose(
        .removesSpacesOfRangeOperator(count: numSpaces, tokenText: exprLastToken.text),
        on: expr
      )

      return exprLastToken.tokenKind == .spacedBinaryOperator(exprLastToken.text) ?
        changeSpacedOperatorToUnspaced(replacedExpression) : replacedExpression
    }
    return expr
  }

  /// Ensures that the trailing trivia of the given expression only has one
  /// trailing space.
  func exprWithOneTrailingSpace(
    expr: ExprSyntax,
    invalidNumSpaces: inout Bool
    ) -> ExprSyntax {
    guard let elementTrailingTrivia = expr.trailingTrivia else { return expr }
    guard let exprLastToken = expr.lastToken else { return expr }
    if elementTrailingTrivia.numberOfSpaces != 1 {
      invalidNumSpaces = true
      let replacedExpr = replaceTrivia(
        on: expr,
        token: exprLastToken,
        trailingTrivia: elementTrailingTrivia.withOneTrailingSpace()
        ) as! ExprSyntax

      diagnose(.addSpaceAfterOperator(tokenText: exprLastToken.text), on: expr)
      return exprLastToken.tokenKind == .unspacedBinaryOperator(exprLastToken.text) ?
        changeSpacedOperatorToUnspaced(replacedExpr) : replacedExpr
    }
    return expr
  }

  /// Given an BinaryOperatorExprSyntax replace the operator type from spacedBinaryOperator
  /// to unspacedBinaryOperator.
  func changeSpacedOperatorToUnspaced(_ expr: ExprSyntax) -> ExprSyntax {
    guard let lastToken = expr.lastToken else { return expr }
    let unspacedExpr = SyntaxFactory.makeBinaryOperatorExpr(
      operatorToken: lastToken.withKind(.unspacedBinaryOperator(lastToken.text))
    )
    return unspacedExpr
  }

  /// Given an BinaryOperatorExprSyntax replace the operator type from unspacedBinaryOperator
  /// to spacedBinaryOperator.
  func changeUnspacedOperatorToSpaced(_ expr: ExprSyntax) -> ExprSyntax {
    guard let lastToken = expr.lastToken else { return expr }
    let unspacedExpr = SyntaxFactory.makeBinaryOperatorExpr(
      operatorToken: lastToken.withKind(.spacedBinaryOperator(lastToken.text))
    )
    return unspacedExpr
  }

  /// Converts the given expression to a Tuple in order to wrap it with parenthesis.
  func addParenthesisToElement(_ element: ExprSyntax) -> TupleExprSyntax {
    let expr = replaceTrivia(
      on: element,
      token: element.lastToken!,
      trailingTrivia: element.trailingTrivia!.withoutSpaces()
      ) as! ExprSyntax
    let leftParen = SyntaxFactory.makeLeftParenToken()
    let rightParen = SyntaxFactory.makeRightParenToken().withOneTrailingSpace()
    let tupleElem = SyntaxFactory.makeBlankTupleElement().withExpression(expr)
    let tupleList = SyntaxFactory.makeTupleElementList([tupleElem])

    return SyntaxFactory.makeTupleExpr(
      leftParen: leftParen,
      elementList: tupleList,
      rightParen: rightParen
    )
  }
 }

 extension Diagnostic.Message {
  static func removesSpacesOfRangeOperator(count: Int, tokenText: String) -> Diagnostic.Message {
    let ending = count == 1 ? "" : "s"
    return Diagnostic.Message(.warning, "remove \(count) space\(ending) after the '\(tokenText)'")
  }

  static func addSpaceAfterOperator(tokenText: String) -> Diagnostic.Message {
    return Diagnostic.Message(.warning, "place only one space after the '\(tokenText)'")
  }
 }
