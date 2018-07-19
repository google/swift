import Foundation
import XCTest
import SwiftSyntax

@testable import Rules

public class NoEmptyTrailingClosureParenthesesTests: DiagnosingTestCase {
  public func testInvalidEmptyParenTrailingClosure() {
    XCTAssertFormatting(
      NoEmptyTrailingClosureParentheses.self,
      input: """
             func greetEnthusiastically(_ nameProvider: () -> String) {
               // ...
             }
             func greetApathetically(_ nameProvider: () -> String) {
               // ...
             }
             greetEnthusiastically() { "John" }
             greetApathetically { "not John" }
             """,
      expected: """
                func greetEnthusiastically(_ nameProvider: () -> String) {
                  // ...
                }
                func greetApathetically(_ nameProvider: () -> String) {
                  // ...
                }
                greetEnthusiastically { "John" }
                greetApathetically { "not John" }
                """)
    XCTAssertDiagnosed(.removeEmptyTrailingParentheses(name: "greetEnthusiastically"))
  }

  #if !os(macOS)
  static let allTests = [
    NoEmptyTrailingClosureParenthesesTests.testInvalidEmptyParenTrailingClosure,
    ]
  #endif

}
