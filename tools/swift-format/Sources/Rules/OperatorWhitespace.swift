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
  let exceptions =  ["...", "..<", ">.."]
  public override func visit(_ token: TokenSyntax) -> Syntax {
    guard let nextToken = token.nextToken else { return token }

    // Operators own their trailing spaces, so ensure it only has 1 space
    // if there's another token in the same line.
    if (token.tokenKind == .unspacedBinaryOperator(token.text) ||
      token.tokenKind == .spacedBinaryOperator(token.text)),
      (!token.trailingTrivia.containsSpaces ||
        token.trailingTrivia.numberOfSpaces > 1),
      !nextToken.leadingTrivia.containsNewlines,
      !exceptions.contains(token.text){
      return placeOneTrailingSpace(token: token)
    }

    // Tokens before the operator should have a single space after.
    if (nextToken.tokenKind == .unspacedBinaryOperator(nextToken.text) ||
      nextToken.tokenKind == .spacedBinaryOperator(nextToken.text)),
      (!nextToken.leadingTrivia.containsSpaces ||
        nextToken.leadingTrivia.numberOfSpaces > 1),
      !token.trailingTrivia.containsNewlines,
      !exceptions.contains(nextToken.text) {
      return placeOneTrailingSpace(token: token)
    }
    return token
  }

  /// Returns a token with a single space in it's leading trivia, and raise
  /// a lint error indicating if the operator needs a space before or after it.
  private func placeOneTrailingSpace(token: TokenSyntax) -> TokenSyntax {
    let numSpaces = token.trailingTrivia.numberOfSpaces
    if numSpaces > 1 {
      diagnose(.removesSpacesAfterOperator(count: numSpaces - 1, binOperator: token.text), on: token)
    }
    else if numSpaces == 0 {
      diagnose(.addSpaceAfterOperator(binOperator: token.text), on: token)
    }
    return token.withOneTrailingSpace()
  }
 }

 extension Diagnostic.Message {
  static func removesSpacesAfterOperator(count: Int, binOperator: String) -> Diagnostic.Message {
    let ending = count == 1 ? "" : "s"
    return Diagnostic.Message(.warning, "remove \(count) space\(ending) after '\(binOperator)'")
  }

  static func addSpaceAfterOperator(binOperator: String) -> Diagnostic.Message {
    return Diagnostic.Message(.warning, "add one space after '\(binOperator)'")
  }
 }
