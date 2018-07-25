import SwiftSyntax

extension DeclSyntax {
  /// Searches through the leading trivia of this decl for a documentation comment.
  public var docComment: String? {
    guard let tok = firstToken else { return nil }
    var comment = [String]()

    // We need to skip trivia until we see the first comment. This trivia will include all the
    // spaces and newlines before the doc comment.
    var hasSeenFirstLineComment = false

    // Look through for discontiguous doc comments, separated by more than 1 newline.
    gatherComments: for piece in tok.leadingTrivia.reversed() {
      switch piece {
      case .docBlockComment(let text):
        // If we see a single doc block comment, then check to see if we've seen any line comments.
        // If so, then use the line comments so far. Otherwise, return this block comment.
        if hasSeenFirstLineComment {
          break gatherComments
        }
        let blockComment = text.components(separatedBy: "\n")
        // Removes the marks of the block comment.
        var isTheFirstLine = true
        let blockCommentWithoutMarks = blockComment.map { (line: String) -> String in
          // Only the first line of the block comment start with '/**'
          let markToRemove = isTheFirstLine ? "/**" : "* "
          let trimmedLine = line.trimmingCharacters(in: .whitespaces)
          if trimmedLine.starts(with: markToRemove) {
            let numCharsToRemove = isTheFirstLine ? markToRemove.count : markToRemove.count - 1
            isTheFirstLine = false
            return trimmedLine.hasSuffix("*/") ?
              String(trimmedLine.dropFirst(numCharsToRemove).dropLast(3)) :
              String(trimmedLine.dropFirst(numCharsToRemove))
          }
          else if trimmedLine == "*" {
            return ""
          }
          else if trimmedLine.hasSuffix("*/") {
            return String(line.dropLast(3))
          }
          isTheFirstLine = false
          return line
        }
        return blockCommentWithoutMarks.joined(separator: "\n").trimmingCharacters(in: .newlines)
      case .docLineComment(let text):
        // Mark that we've started grabbing sequential line comments and append it to the
        // comment buffer.
        hasSeenFirstLineComment = true
        comment.append(text)
      case .newlines(let n), .carriageReturns(let n), .carriageReturnLineFeeds(let n):
        // Only allow for 1 newline between doc line comments, but allow for newlines between the
        // doc comment and the declaration.
        guard n == 1 || !hasSeenFirstLineComment else { break gatherComments }
      case .spaces, .tabs:
        // Skip all spaces/tabs. They're irrelevant here.
        break
      default:
        if hasSeenFirstLineComment {
          break gatherComments
        }
      }
    }

    /// Removes the "///" from every line of comment
    let docLineComments = comment.reversed().map { $0.dropFirst(3) }
    return comment.isEmpty ? nil : docLineComments.joined(separator: "\n")
  }
}
