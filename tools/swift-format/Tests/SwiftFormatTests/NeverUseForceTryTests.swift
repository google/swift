import Foundation
import XCTest
import SwiftSyntax

@testable import Rules

public class NeverUseForceTryTests: DiagnosingTestCase {
  public func testInvalidTryExpression() {
    let input =
      """
      let document = try! Document(path: "important.data")
      let document = try Document(path: "important.data")
      let x = try! someThrowingFunction()
      if let data = try? fetchDataFromDisk() { return data }
      """
    performLint(NeverUseForceTry.self, input: input)
    XCTAssertDiagnosed(.doNotForceTry)
    XCTAssertDiagnosed(.doNotForceTry)
    XCTAssertNotDiagnosed(.doNotForceTry)
  }

  public func testAllowForceTryInTestCode() {
    let input =
      """
      import XCTest

      let document = try! Document(path: "important.data")
      """
    performLint(NeverUseForceTry.self, input: input)
    XCTAssertNotDiagnosed(.doNotForceTry)
  }
}
