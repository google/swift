import Foundation
import SwiftSyntax
import XCTest

@testable import Rules

public class OnlyOneTrailingClosureArgumentTests: DiagnosingTestCase {
  public func testInvalidTrailingClosureCall() {
    let input =
      """
      callWithBoth(someClosure: {}) {
        // ...
      }
      callWithClosure(someClosure: {})
      callWithTrailingClosure {
        // ...
      }
      """
    performLint(OnlyOneTrailingClosureArgument.self, input: input)
    XCTAssertDiagnosed(.removeTrailingClosure)
    XCTAssertNotDiagnosed(.removeTrailingClosure)
    XCTAssertNotDiagnosed(.removeTrailingClosure)
  }

  #if !os(macOS)
  static let allTests = [
    OnlyOneTrailingClosureArgumentTests.testInvalidTrailingClosureCall,
    ]
  #endif
}
