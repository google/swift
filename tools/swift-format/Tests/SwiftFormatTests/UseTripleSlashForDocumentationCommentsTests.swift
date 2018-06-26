import SwiftSyntax
import XCTest

@testable import Rules

public class UseTripleSlashForDocumentationCommentsTests: DiagnosingTestCase {
  public func testRemoveDocBlockComments() {
    XCTAssertFormatting(
      UseTripleSlashForDocumentationComments.self,
      input: """
             /**
              * Returns the numeric value of the given digit represented as a Unicode scalar.
              *
              * - Parameters:
              *   - digit: The Unicode scalar whose numeric value should be returned.
              *   - radix: The radix, between 2 and 36, used to compute the numeric value.
              * - Returns: The numeric value of the scalar.
              */
             func /**DocBlock*/ numericValue(of digit: UnicodeScalar, radix: Int = 10) -> Int {}

             /**End of a file*/
             """,
      expected: """
                /// Returns the numeric value of the given digit represented as a Unicode scalar.
                ///
                /// - Parameters:
                ///   - digit: The Unicode scalar whose numeric value should be returned.
                ///   - radix: The radix, between 2 and 36, used to compute the numeric value.
                /// - Returns: The numeric value of the scalar.
                func /**DocBlock*/ numericValue(of digit: UnicodeScalar, radix: Int = 10) -> Int {}

                /// End of a file
                """)
  }
  
  public func testRemoveDocBlockCommentsWithoutStars() {
    XCTAssertFormatting(
      UseTripleSlashForDocumentationComments.self,
      input: """
             /**
             Returns the numeric value of the given digit represented as a Unicode scalar.

             - Parameters:
                - digit: The Unicode scalar whose numeric value should be returned.
                - radix: The radix, between 2 and 36, used to compute the numeric value.
             - Returns: The numeric value of the scalar.
             */
             func numericValue(of digit: UnicodeScalar, radix: Int = 10) -> Int {}
             """,
      expected: """
                /// Returns the numeric value of the given digit represented as a Unicode scalar.
                ///
                /// - Parameters:
                ///   - digit: The Unicode scalar whose numeric value should be returned.
                ///   - radix: The radix, between 2 and 36, used to compute the numeric value.
                /// - Returns: The numeric value of the scalar.
                func numericValue(of digit: UnicodeScalar, radix: Int = 10) -> Int {}
                """)
  }
  
  #if !os(macOS)
  static let allTests = [
    UseTripleSlashForDocumentationCommentsTests.testRemoveDocBlockComments,
    UseTripleSlashForDocumentationCommentsTeststestRemoveDocBlockCommentsWithoutStars,
    ]
  #endif
}
