import SwiftSyntax
import XCTest

@testable import Rules

public class OperatorWhitespaceTests: DiagnosingTestCase {
  public func testInvalidOperatorWhitespace() {
    XCTAssertFormatting(
      OperatorWhitespace.self,
      input: """
             var a = -10  +    3
             var e = 1 + 2 * (10 / 7)
             a*=2
             let b: UInt8 = 4
             b       << 1
             b>>=2
             let c: UInt8 = 0b00001111
             let d = ~c
             struct AnyEquatable<Wrapped : Equatable> : Equatable {}
             func foo(param: x  &  y) {}
             """,
      expected: """
                var a = -10 + 3
                var e = 1 + 2 * (10 / 7)
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
  
  public func testRangeOperators() {
    XCTAssertFormatting(
      OperatorWhitespace.self,
      input: """
             for number in 1 ... 5 {}
             for number in -10 ... -5 {}
             var elements = [1,2,3]
             let rangeA = elements.count ... 10
             for number in 1...5 {}
             """,
      expected: """
                for number in 1...5 {}
                for number in -10...(-5) {}
                var elements = [1,2,3]
                let rangeA = elements.count...10
                for number in 1...5 {}
                """)
  }
  
  public func testCompositeTypes() {
    XCTAssertFormatting(
      OperatorWhitespace.self,
      input: """
             func foo(param: x & y) {}
             func foo(param: x&y) {}
             func foo(param: x    &     y) {}
             func foo(param: x& y) {}
             """,
      expected: """
                func foo(param: x & y) {}
                func foo(param: x & y) {}
                func foo(param: x & y) {}
                func foo(param: x & y) {}
                """)
  }
  
  #if !os(macOS)
  static let allTests = [
    OperatorWhitespaceTests.testInvalidOperatorWhitespace,
    OperatorWhitespaceTests.testRangeOperators,
    OperatorWhitespaceTests.testCompositeTypes
    ]
  #endif
}
