import SwiftSyntax
import XCTest

@testable import Rules

public class OneSpaceAfterKeywordsTests: DiagnosingTestCase {
  public func testInvalidOneSpaceAfterKeywordsTests() {
    XCTAssertFormatting(
      OneSpaceAfterKeywords.self,
      input: """
             let   v1 = "Test"
             var             values: Values
             func isIdentifier(_       tokKind: TokenKind) -> Bool {
               guard     let     first = v1.first else { return false }
               if case .identifier(_) = tokKind {
                 return               true
               }
               return  false
             }
             """,
      expected: """
                let v1 = "Test"
                var values: Values
                func isIdentifier(_ tokKind: TokenKind) -> Bool {
                  guard let first = v1.first else { return false }
                  if case .identifier(_) = tokKind {
                    return true
                  }
                  return false
                }
                """)
  }
  
  #if !os(macOS)
  static let allTests = [
    OneSpaceAfterKeywordsTests.testInvalidOneSpaceAfterKeywordsTests,
    ]
  #endif
}
