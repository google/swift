import Foundation
import XCTest
import SwiftSyntax

@testable import Rules

public class UseShorthandTypeNamesTests: DiagnosingTestCase {
  public func testLongFormNames() {
    XCTAssertFormatting(
      UseShorthandTypeNames.self,
      input: """
             func enumeratedDictionary<Element>(
               from values: Array<Element>,
               start: Optional<Array<Element>.Index> = nil
             ) -> Dictionary<Int, Array<Element>> {
               // Specializer syntax
               Array<Array<Optional<Int>>.Index>.init()
               // More specializer syntax
               Array<[Int]>.init()
             }
             func nestedLongForms(
               x: Array<Dictionary<String, Int>>,
               y: Dictionary<Array<Optional<String>>, Optional<Int>>) {
               Dictionary<Array<Int>.Index, String>.init()
               Dictionary<String, Optional<Float>>.init()
             }
             """,
      expected: """
                func enumeratedDictionary<Element>(
                  from values: [Element],
                  start: Array<Element>.Index? = nil
                ) -> [Int: [Element]] {
                  // Specializer syntax
                  [Array<Int?>.Index].init()
                  // More specializer syntax
                  [[Int]].init()
                }
                func nestedLongForms(
                  x: [[String: Int]],
                  y: [[String?]: Int?]) {
                  [Array<Int>.Index: String].init()
                  [String: Float?].init()
                }
                """)
  }

  #if !os(macOS)
  static let allTests = [
    UseShorthandTypeNamesTests.testLongFormNames,
    ]
  #endif
}
