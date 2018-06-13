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
    guard let nextToken = token.nextToken else {
      // In the case there is a line comment at the end of the file, it ensures
      // that the line comment has a single space after the `//`.
      pieces = checksSpacesAfterLineComment(token: token)
      return token.withLeadingTrivia(Trivia.init(pieces: pieces.reversed()))
    }
    
    // Ensures the line comment has at least 2 spaces before the `//`.
    if hasLineComment(trivia: nextToken.leadingTrivia) {
      let numSpaces = token.trailingTrivia.numberOfSpaces
      if numSpaces < 2 {
        let addSpaces = 2 - numSpaces
        diagnose(.addSpacesBeforeLineComment(count: addSpaces), on:token)
        validToken = token.withTrailingTrivia(token.trailingTrivia.appending(.spaces(addSpaces)))
      }
    }
    pieces = checksSpacesAfterLineComment(token: token)
    return validToken.withLeadingTrivia(Trivia.init(pieces: pieces.reversed()))
  }
  
  /// Returns a boolean indicating if the given trivia contains a line comment.
  private func hasLineComment (trivia: Trivia) -> Bool {
    // When the comment isn't inline with code, it doesn't need to
    // to check that there are two spaces before the line comment.
    if let firstPiece = trivia.reversed().last {
      if case .newlines(_) = firstPiece {
        return false
      }
    }
    for piece in trivia.reversed() {
      if case .lineComment(_) = piece {
        return true
      }
    }
    return false
  }
  
  /// Ensures the line comment has exactly one space after `//`.
  private func checksSpacesAfterLineComment(token: TokenSyntax) -> [TriviaPiece] {
    var pieces = [TriviaPiece]()
    for piece in token.leadingTrivia.reversed() {
      if case .lineComment(var text) = piece,
        invalidLineComment(textLineComment: &text, token: token){
        pieces.append(TriviaPiece.lineComment(text))
      }
      else {
        pieces.append(piece)
      }
    }
    return pieces
  }
  
  /// Returns a boolean indicating if the comment had an invalid format,
  /// if it does, the text of the comment is modified to the correct format.
  private func invalidLineComment (textLineComment: inout String, token: TokenSyntax) -> Bool {
    let text = textLineComment.dropFirst(2)
    if text.first != " " {
      diagnose(.addSpaceAfterLineComment, on: token)
      textLineComment = "// " + text.trimmingCharacters(in: .whitespaces)
      return true
    }
    else if text.dropFirst(1).first == " " {
      diagnose(.removeSpacesAfterLineComment, on: token)
      textLineComment = "// " + text.trimmingCharacters(in: .whitespaces)
      return true
    }
    return false
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
