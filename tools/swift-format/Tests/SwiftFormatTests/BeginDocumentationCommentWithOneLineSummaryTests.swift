import Foundation
import SwiftSyntax
import XCTest

@testable import Rules

public class BeginDocumentationCommentWithOneLineSummaryTests: DiagnosingTestCase {
  public func testDocLineCommentsWithoutOneSentenceSummary() {
    let input =
      """
      /// Returns a bottle of Dr. Pepper from the vending machine.
      public func drPepper(from vendingMachine: VendingMachine) -> Soda {}

      /// Contains a comment as description that needs a sentece
      /// of two lines of code.
      public var twoLinesForOneSentence = "test"

      /// The background color of the view.
      var backgroundColor: UIColor

      /// Returns the sum of the numbers.
      ///
      /// - Parameter numbers: The numbers to sum.
      /// - Returns: The sum of the numbers.
      func sum(_ numbers: [Int]) -> Int {
      // ...
      }

      /// This docline should not succeed.
      /// There are two sentences without a blank line between them.
      struct Test {}

      /// This docline should not succeed. There are two sentences.
      public enum Token { case comma, semicolon, identifier }
      """
    performLint(BeginDocumentationCommentWithOneLineSummary.self, input: input)
    XCTAssertDiagnosed(.docCommentRequiresOneSentenceSummary("This docline should not succeed."))
    XCTAssertDiagnosed(.docCommentRequiresOneSentenceSummary("This docline should not succeed."))
    
    XCTAssertNotDiagnosed(.docCommentRequiresOneSentenceSummary(
      "Returns a bottle of Dr. Pepper from the vending machine."))
    XCTAssertNotDiagnosed(.docCommentRequiresOneSentenceSummary(
      "Contains a comment as description that needs a sentece of two lines of code."))
    XCTAssertNotDiagnosed(.docCommentRequiresOneSentenceSummary("The background color of the view."))
    XCTAssertNotDiagnosed(.docCommentRequiresOneSentenceSummary("Returns the sum of the numbers."))
  }

  public func testBlockLineCommentsWithoutOneSentenceSummary() {
    let input =
    """
      /**
       * Returns the numeric value.
       *
       * - Parameters:
       *   - digit: The Unicode scalar whose numeric value should be returned.
       *   - radix: The radix, between 2 and 36, used to compute the numeric value.
       * - Returns: The numeric value of the scalar.*/
      func numericValue(of digit: UnicodeScalar, radix: Int = 10) -> Int {}

      /**
       * This block comment contains a sentence summary
       * of two lines of code.
       */
      public var twoLinesForOneSentence = "test"

      /**
       * This block comment should not succeed, struct.
       * There are two sentences without a blank line between them.
       */
      struct TestStruct {}

      /**
      This block comment should not succeed, class.
      Add a blank comment after the first line.
      */
      public class TestClass {}
      /** This block comment should not succeed, enum. There are two sentences. */
      public enum testEnum {}
      """
    performLint(BeginDocumentationCommentWithOneLineSummary.self, input: input)
    XCTAssertDiagnosed(.docCommentRequiresOneSentenceSummary("This block comment should not succeed, struct."))
    XCTAssertDiagnosed(.docCommentRequiresOneSentenceSummary("This block comment should not succeed, class."))
    XCTAssertDiagnosed(.docCommentRequiresOneSentenceSummary("This block comment should not succeed, enum."))
    
    XCTAssertNotDiagnosed(.docCommentRequiresOneSentenceSummary("Returns the numeric value."))
    XCTAssertNotDiagnosed(.docCommentRequiresOneSentenceSummary(
      "This block comment contains a sentence summary of two lines of code."))
  }

  #if !os(macOS)
  static let allTests = [
    BeginDocumentationCommentWithOneLineSummaryTests.testDocLineCommentsWithoutOneSentenceSummary,
    BeginDocumentationCommentWithOneLineSummaryTests.testBlockLineCommentsWithoutOneSentenceSummary
    ]
  #endif
}
