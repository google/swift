import Foundation
import XCTest
import SwiftSyntax

@testable import Rules

public class ReturnVoidInsteadOfEmptyTupleTests: DiagnosingTestCase {
  public func testEmptyTupleReturns() {
    XCTAssertFormatting(
      ReturnVoidInsteadOfEmptyTuple.self,
      input: """
             let callback: () -> ()
             typealias x = Int -> ()
             func y() -> Int -> () { return }
             func z(d: Bool -> ()) {}
             """,
      expected: """
                let callback: () -> Void
                typealias x = Int -> Void
                func y() -> Int -> Void { return }
                func z(d: Bool -> Void) {}
                """)
  }

  #if !os(macOS)
  static let allTests = [
    ReturnVoidInsteadOfEmptyTupleTests.testEmptyTupleReturns,
    ]
  #endif
}
