import Foundation
import SwiftSyntax
import XCTest

@testable import Rules

public class IdentifiersMustBeASCIITests: DiagnosingTestCase {
  public func testInvalidIdentifiers() {
    let input =
    """
      let Te$t = 1
      var fo😎o = 2
      let Δx = newX - previousX
      var 🤩😆 = 20
      """
    performLint(IdentifiersMustBeASCII.self, input: input)
    XCTAssertDiagnosed(.nonASCIICharsNotAllowed(["😎"],"fo😎o"))
    XCTAssertDiagnosed(.nonASCIICharsNotAllowed(["🤩", "😆"], "🤩😆"))
  }
  
  #if !os(macOS)
  static let allTests = [
    IdentifiersMustBeASCIITests.testInvalidIdentifiers,
    ]
  #endif
}
