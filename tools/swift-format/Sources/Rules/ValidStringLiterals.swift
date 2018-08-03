import Core
import Foundation
import SwiftSyntax

/// Enforces restrictions on unicode escape sequences/characters in string literals.
///
/// String literals will not mix unicode escape sequences with, and will
/// not consist of a single un-escaped Unicode control character, combining character, or variant
/// selector.
///
/// Lint: If a string consists of only Unicode control characters, combining characters, or variant
///       selectors, a lint error is raised.
///       If a string mixes non-ASCII characters and Unicode escape sequences, a lint error is
///       raised.
/// Format: String literals consisting of only Unicode modifiers will be replaced with the
///         equivalent unicode escape sequences.
///         String literals which mix non-ASCII characters and Unicode escape sequences will have
///         their unicode escape sequences replaced with the corresponding Unicode character.
///
/// - SeeAlso: https://google.github.io/swift#invisible-characters-and-modifiers
///            https://google.github.io/swift#string-literals
public final class ValidStringLiterals: SyntaxFormatRule {
  public override func visit(_ node: StringLiteralExprSyntax) -> ExprSyntax {
    // Since the string literal has the raw value of the string, it begins and ends
    // with quatation marks. Removes only the first quatation mark, the last one would
    // be used in order to iterate the whole text of the string literal.
    var stringText = String(node.stringLiteral.text.dropFirst())

    // Ignores all diacritic marks.
    let textWithoutModifiers = stringText.dropLast().folding(
      options: .diacriticInsensitive,
      locale: .current
    )

    // Ensures the string does not consists of a single un-escaped Unicode control character,
    // if it does that single character is replaced by its escaped Unicode sequence.
    if textWithoutModifiers.count == 1,
      let firstChar = textWithoutModifiers.unicodeScalars.first,
      !firstChar.isASCII {
      let escapedUnicodeValue = String(format: "%04X", firstChar.value)
      diagnose(.replaceUnicodeCharacter, on: node)
      return SyntaxFactory.makeStringLiteralExpr(("\\u{\(escapedUnicodeValue)}"))
    }

    // If the string mixes non-ASCII characters and Unicode escape sequences, the sequences
    // are replaces with the corresponding Unicode Literal.
    let containsNonASCII = stringText.unicodeScalars.contains { !$0.isASCII }
    if containsNonASCII {
      let textWithoutEscapeSequences = replaceEscapeSequencesWithUnicodeLiteral(stringText, node)
      return stringText == textWithoutEscapeSequences ? node :
        SyntaxFactory.makeStringLiteralExpr(textWithoutEscapeSequences)
    }
    return node
  }

  /// Returns a string without any unicode escape sequence.
  func replaceEscapeSequencesWithUnicodeLiteral(
    _ stringText: String,
    _ node: StringLiteralExprSyntax
    ) -> String {
    var hasFoundEscapeSequence = false
    var omittCharacter = false
    var textWithoutEscapeSequences = ""

    // Iterates through the string replacing the escape sequences with its corresponding
    // Unicode literal.
    guard var previousChar = stringText.first else { return stringText }
    for (index, char) in stringText.dropFirst().enumerated() {
      if previousChar == "\\" && char == "u" {
        // Drops all the characters that have been already processed, in order to have
        // the position where the sequence starts.
        let sliceText = stringText.dropFirst(index)
        // Finds the position of the closing bracket of the escape sequence.
        guard let ends = sliceText.firstIndex(of: "}") else { continue }
        let escapeSequence = String(stringText[sliceText.startIndex...ends])
        // Converts the escaped sequence to its corresponding Unicode literal.
        guard let unicodeLiteral = escapedSequenceToUnicodeLiteral(escapeSequence) else { continue }
        textWithoutEscapeSequences.append(unicodeLiteral)
        diagnose(.replaceEscapedSequence(escapeSequence: escapeSequence), on: node)
        // Indicates that the character is part of the escaped sequence, which should be omitted.
        omittCharacter = true
        hasFoundEscapeSequence = true
      }
      else if !omittCharacter {
        textWithoutEscapeSequences.append(previousChar)
      }
      else if omittCharacter && previousChar == "}" {
        omittCharacter = false
      }
      previousChar = char
    }
    return hasFoundEscapeSequence ? textWithoutEscapeSequences : stringText
  }

  /// Returns the corresponding Unicode literal from the given escape sequence.
  func escapedSequenceToUnicodeLiteral(_ escapedSequence: String) -> String? {
    let hexValue = escapedSequence.trimmingCharacters(in: .init(charactersIn: "\\u{}"))
    guard let unicodeValue = UInt32(hexValue, radix: 16) else { return nil }
    guard let unicodeLiteral = UnicodeScalar(unicodeValue) else { return nil }
    return String(unicodeLiteral)
  }
}

extension Diagnostic.Message {
  static let replaceUnicodeCharacter =
    Diagnostic.Message(
      .warning,
      "replace the single Unicode character with its corresponding escape sequence"
  )

  static func replaceEscapedSequence(escapeSequence: String) -> Diagnostic.Message {
    return Diagnostic.Message(
      .warning,
      "replace the Unicode escape sequence with its corresponding Unicode character"
    )
  }
}
