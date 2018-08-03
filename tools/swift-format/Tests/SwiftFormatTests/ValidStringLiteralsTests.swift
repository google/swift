import Foundation
import XCTest
import SwiftSyntax

@testable import Rules

public class ValidStringLiteralsTests: DiagnosingTestCase {
  public func testInvalidStringLiteral() {
    XCTAssertFormatting(
      ValidStringLiterals.self,
      input: """
             let code = "🏿"
             let onlyEscapedSequences = "\\u{00DC}bergr\\u{00F6}\\u{00DF}e\\n"
             let onlyNonAsciiLiteralChars = "Übergröße"
             let mixFormat = "Übergr\\u{00F6}\\u{00DF}e\\n"
             let umlaut = "ü"
             """,
      expected: """
                let code = "\\u{1F3FF}"
                let onlyEscapedSequences = "\\u{00DC}bergr\\u{00F6}\\u{00DF}e\\n"
                let onlyNonAsciiLiteralChars = "Übergröße"
                let mixFormat = "Übergröße\\n"
                let umlaut = "ü"
                """)
  }

  #if !os(macOS)
  static let allTests = [
    ValidStringLiteralsTests.testInvalidStringLiteral,
    ]
  #endif
}
