import Foundation
import XCTest
import SwiftSyntax

@testable import Rules

public class OneSpaceInsideBracesTests: DiagnosingTestCase {
  public func testInvalidSpacesInsideBraces() {
    XCTAssertFormatting(
      OneSpaceInsideBraces.self,
      input: """
             let nonNegativeCubes = numbers.map {$0 * $0 * $0    }.filter {  $0 >= 0}
             func foo() {}
             func bar() {  }
             guard x = y else {return nil  }
             if y > x {
               // ...
             }
             func baz() {if(true) {  print("yes!")}}
             """,
      expected: """
                let nonNegativeCubes = numbers.map { $0 * $0 * $0 }.filter { $0 >= 0 }
                func foo() {}
                func bar() {}
                guard x = y else { return nil }
                if y > x {
                  // ...
                }
                func baz() { if(true) { print("yes!") } }
                """)
    XCTAssertDiagnosed(.insertSpaceAfterOpenBrace)
    XCTAssertDiagnosed(.removeSpaceBeforeCloseBrace)
    XCTAssertDiagnosed(.removeSpaceAfterOpenBrace)
    XCTAssertDiagnosed(.insertSpaceAfterOpenBrace)
    XCTAssertDiagnosed(.removeSpaceBeforeCloseBrace)
    XCTAssertDiagnosed(.insertSpaceAfterOpenBrace)
    XCTAssertDiagnosed(.removeSpaceAfterOpenBrace)
    XCTAssertDiagnosed(.insertSpaceBeforeCloseBrace)
    XCTAssertDiagnosed(.insertSpaceBeforeCloseBrace)
  }

  #if !os(macOS)
  static let allTests = [
    OneSpaceInsideBracesTests.testInvalidSpacesInsideBraces,
    ]
  #endif
}
