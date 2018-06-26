import Core
import Foundation
import SwiftSyntax

/// Documentation comments must use the `///` form.
///
/// This is similar to `NoBlockComments` but is meant to prevent documentation block comments.
///
/// Lint: If a doc block comment appears, a lint error is raised.
///
/// Format: If a doc block comment appears on its own on a line, or if a doc block comment spans multiple
///         lines without appearing on the same line as code, it will be replaced with multiple
///         doc line comments.
///
/// - SeeAlso: https://google.github.io/swift#general-format
public final class UseTripleSlashForDocumentationComments: SyntaxFormatRule {
  public override func visit (_ token: TokenSyntax) -> Syntax {
    var pieces = [TriviaPiece]()
    var isInvalid = false
    
    // Ensures that all doc block comments are replaced with doc line comment,
    // unless the comment is between tokens on the same line.
    for piece in token.leadingTrivia {
      if case .docBlockComment(let text) = piece,
         !commentIsBetweenCode(token) {
        isInvalid = true
        diagnose(.avoidDocBlockComment, on: token)
        let docLineCommentText = convertsDocBlockCommentToDocLineComment(text)
        let docLineComment = TriviaPiece.docLineComment(docLineCommentText)
        pieces.append(docLineComment)
      }
      else {
        pieces.append(piece)
      }
    }
    return isInvalid ? token.withLeadingTrivia(Trivia.init(pieces: pieces)) : token
  }
  
  /// Indicates if a doc block comment is between tokens on the same line.
  /// If it does, it should only raise a lint error.
  func commentIsBetweenCode(_ token: TokenSyntax) -> Bool {
    let hasCommentBetweenCode = token.leadingTrivia.isBetweenTokens
    if hasCommentBetweenCode {
      diagnose(.avoidDocBlockComment, on: token)
    }
    return hasCommentBetweenCode
  }
  
  /// Converts the text of doc block comment into a format for a doc line comment.
  func convertsDocBlockCommentToDocLineComment(_ text: String) -> String {
    // Removes the '/**', '*/', the extra spaces and newlines from the comment.
    let docText = text.dropFirst(3).dropLast(2).trimmingCharacters(in: .whitespacesAndNewlines)
    let splitComment = docText.split(separator: "\n", omittingEmptySubsequences: false)
    var newLine: String
    var docBlockText = [String]()
    
    // Process each line of the doc block comment and removes the '*' if needed.
    for line in splitComment {
      newLine = line.trimmingCharacters(in: .whitespaces)
      if let range = newLine.range(of: "*") {
        docBlockText.append(newLine.replacingOccurrences(of: "*", with: "///" , range: range))
      }
      else {
        let startsComment = line.starts(with: " ") || line.count == 0 ? "///" : "/// "
        docBlockText.append(startsComment + line)
      }
    }
    return docBlockText.joined(separator: "\n")
  }
}

extension Diagnostic.Message {
  static let avoidDocBlockComment = Diagnostic.Message(.warning, "Doc block comments should be avoided in favor of  doc line comments.")
  static let avoidDocBlockCommentBetweenCode = Diagnostic.Message(.warning, "Avoid comments when they are at the same line between code")
}
