import SwiftSyntax
import XCTest

@testable import Rules

public class CommentWhitespaceTest: DiagnosingTestCase {
  public func testInvalidCommentWhiteSpace() {
    XCTAssertFormatting(
    CommentWhitespace.self,
    input: """
           let initialFactor = 2 //        Line comment of initialFactor.
           let finalFactor = 2//Line comment of finalFactor.

           //Lorem ipsum dolor sit amet, at nonumes adipisci sea, natum
           //       offendit vis ex. Audiam legendos expetenda ei quo, nonumes
           // msensibus eloquentiam ex vix.
           let fin = 3//        End of file.
           """,
    expected: """
              let initialFactor = 2  // Line comment of initialFactor.
              let finalFactor = 2  // Line comment of finalFactor.

              // Lorem ipsum dolor sit amet, at nonumes adipisci sea, natum
              // offendit vis ex. Audiam legendos expetenda ei quo, nonumes
              // msensibus eloquentiam ex vix.
              let fin = 3  // End of file.
              """)
  }
  
  public func testInvalidFuncCommentWhiteSpace() {
    XCTAssertFormatting(
    CommentWhitespace.self,
    input: """
           func testLineComment(paramA: Int) -> Int {
             //LineComment.
             if paramA < 50 {
               //LineComment.
               return paramA - 100
             }
             //LineComment.
             return paramA + 100
           }
           """,
    expected: """
              func testLineComment(paramA: Int) -> Int {
                // LineComment.
                if paramA < 50 {
                  // LineComment.
                  return paramA - 100
                }
                // LineComment.
                return paramA + 100
              }
              """)
  }
  
  #if !os(macOS)
  static let allTests = [
    CommentWhitespaceTest.testInvalidCommentWhiteSpace,
    CommentWhitespaceTest.testInvalidFuncCommentWhiteSpace,
    ]
  #endif
}
