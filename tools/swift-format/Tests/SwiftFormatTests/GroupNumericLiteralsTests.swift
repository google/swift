import Foundation
import XCTest
import SwiftSyntax

@testable import Rules

public class GroupNumericLiteralsTests: DiagnosingTestCase {
  public func testNumericGrouping() {
    XCTAssertFormatting(
      GroupNumericLiterals.self,
      input: """
             let a = 9876543210
             let b = 1234
             let c = 0x34950309233
             let d = -0x34242
             let e = 0b10010010101
             let f = 0b101
             let g = 11_15_1999
             let h = 0o21743
             let i = -53096828347
             """,
      expected: """
                let a = 9_876_543_210
                let b = 1234
                let c = 0x349_5030_9233
                let d = -0x34242
                let e = 0b100_10010101
                let f = 0b101
                let g = 11_15_1999
                let h = 0o21743
                let i = -53_096_828_347
                """)
    XCTAssertDiagnosed(.groupNumericLiteral(by: 3))
    XCTAssertDiagnosed(.groupNumericLiteral(by: 3))
    XCTAssertNotDiagnosed(.groupNumericLiteral(by: 3))
    XCTAssertDiagnosed(.groupNumericLiteral(by: 4))
    XCTAssertNotDiagnosed(.groupNumericLiteral(by: 4))
    XCTAssertDiagnosed(.groupNumericLiteral(by: 8))
    XCTAssertNotDiagnosed(.groupNumericLiteral(by: 8))
  }
  
  #if !os(macOS)
  static let allTests = [
    GroupNumericLiterals.testNumericGrouping,
    ]
  #endif
  
}
