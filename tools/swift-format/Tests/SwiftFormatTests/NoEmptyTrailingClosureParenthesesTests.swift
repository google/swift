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
             func myfunc(cls: MyClass) {
               cls.myClosure { $0 }
             }
             func myfunc(cls: MyClass) {
               cls.myBadClosure() { $0 }
             }
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
                func myfunc(cls: MyClass) {
                  cls.myClosure { $0 }
                }
                func myfunc(cls: MyClass) {
                  cls.myBadClosure { $0 }
                }
                """)
    XCTAssertDiagnosed(.removeEmptyTrailingParentheses(name: "greetEnthusiastically"))
    XCTAssertDiagnosed(.removeEmptyTrailingParentheses(name: "myBadClosure"))
    XCTAssertNotDiagnosed(.removeEmptyTrailingParentheses(name: "myClosure"))
  }

  #if !os(macOS)
  static let allTests = [
    NoEmptyTrailingClosureParenthesesTests.testInvalidEmptyParenTrailingClosure,
    ]
  #endif

}
