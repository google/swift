import SwiftSyntax
import XCTest

@testable import Rules

public class OperatorWhitespaceTests: DiagnosingTestCase {
  public func testInvalidOperatorWhitespace() {
    XCTAssertFormatting(
      OperatorWhitespace.self,
      input: """
             for number in 1...5 {}
             var a = -10  +    3
             a*=2
             let b: UInt8 = 4
             b       << 1
             b>>=2
             let c: UInt8 = 0b00001111
             let d = ~c
             struct AnyEquatable<Wrapped : Equatable> : Equatable {}
             func foo(param: x&y) {}
             """,
      expected: """
                for number in 1...5 {}
                var a = -10 + 3
                a *= 2
                let b: UInt8 = 4
                b << 1
                b >>= 2
                let c: UInt8 = 0b00001111
                let d = ~c
                struct AnyEquatable<Wrapped : Equatable> : Equatable {}
                func foo(param: x & y) {}
                """)
  }
  
  #if !os(macOS)
  static let allTests = [
    OperatorWhitespaceTests.testInvalidOperatorWhitespace,
    ]
  #endif
}
