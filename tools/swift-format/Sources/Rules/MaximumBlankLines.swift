import Core
import Foundation
import SwiftSyntax

/// Enforce a maximum number of consecutive blank lines.
///
/// Lines containing only whitespace characters are considered blank (e.g. "^\s*$"). Multi-line
/// string literals are ignored by this rule.
///
/// Lint: A lint error is raised if more than maximumBlankLines appear consecutively.
///
/// Format: If more than maximumBlankLines appear consecutively they are reduced to a count of
///         maximumBlankLines.
///
/// Configuration: maximumBlankLines
///
/// - SeeAlso: https://google.github.io/swift#vertical-whitespace
public final class MaximumBlankLines: SyntaxFormatRule {
  public override func visit(_ token: TokenSyntax) -> Syntax {
    guard let parentToken = token.parent else {
      return token.withLeadingTrivia(removeExtraBlankLines(token).0)
    }
    
    guard let grandparentTok = parentToken.parent else {
      return token.withLeadingTrivia(removeExtraBlankLines(token).0)
    }
    
    // Tokens who appeared in a member type are handle by
    // BlankLineBetweenMembers rule.
    if grandparentTok is MemberDeclListItemSyntax {
      return token
    }
    else {
      let correctTrivia = removeExtraBlankLines(token)
      return correctTrivia.1 ? token : token.withLeadingTrivia(removeExtraBlankLines(token).0)
    }
  }
  
  /// Indicates if the given trivia contains an invalid amount of
  /// consecutively blank lines. If it does it returns a clean trivia
  /// with the correct amount of blank lines.
  func removeExtraBlankLines(_ token: TokenSyntax) -> (Trivia, Bool) {
    let maxBlankLines = context.configuration.maximumBlankLines
    var pieces = [TriviaPiece]()
    let isTheFirstOne = token == token.root.firstToken
    let tokenTrivia = token.leadingTrivia
    var startsIn = 0
    var hasValidAmountOfBlankLines = true
    
    // Ensures the beginning of file doesn't have an invalid amount of blank line.
    // The first triviapiece of a file is a special case, where each newline is
    // a blank line.
    if isTheFirstOne, let firstPiece = tokenTrivia.first,
       case TriviaPiece.newlines(let num) = firstPiece, num > maxBlankLines {
      pieces.append(.newlines(maxBlankLines))
      diagnose(.removeMaxBlankLines(count: num - maxBlankLines), on: token)
      startsIn = 1
      hasValidAmountOfBlankLines = false
    }
    
    // Iterates through the token trivia, verifying that the number on blank
    // lines in the file do not exceed the maximumBlankLines.
    for index in startsIn..<tokenTrivia.count {
      if case .newlines(let num) = tokenTrivia[index],
         num - 1 > maxBlankLines {
        pieces.append(TriviaPiece.newlines(maxBlankLines + 1))
        diagnose(.removeMaxBlankLines(count: num - maxBlankLines), on: token)
        hasValidAmountOfBlankLines = false
      }
      else {
        pieces.append(tokenTrivia[index])
      }
    }
    return (Trivia.init(pieces: pieces), hasValidAmountOfBlankLines)
  }
}

extension Diagnostic.Message {
  static func removeMaxBlankLines(count: Int) -> Diagnostic.Message {
    let ending = count == 1 ? "" : "s"
    return Diagnostic.Message(.warning, "remove \(count) blank line\(ending)")
  }
}
