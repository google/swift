import SwiftSyntax
import XCTest

@testable import Rules

public class CommaWhitespaceTests: DiagnosingTestCase {
  public func testInvalidFuncCommaWhiteSpace() {
    XCTAssertFormatting(
      CommaWhitespace.self,
      input: """
             func testComma(paramA: Bool,paramB: Bool ,paramC: Bool , paramD: Bool) -> Bool {

             if paramA,
                !paramB ,
                paramC   ,
                paramD {
              return true
                }
             return false
             }
             """,
      expected: """
                func testComma(paramA: Bool, paramB: Bool, paramC: Bool, paramD: Bool) -> Bool {

                if paramA,
                   !paramB,
                   paramC,
                   paramD {
                 return true
                   }
                return false
                }
                """)
  }
  
  public func testInvalidDeclCommaWhiteSpace() {
    XCTAssertFormatting(
      CommaWhitespace.self,
      input: """
             let numA = [1,2,3]
             let numB = [1 ,2 ,3]
             let numC = [1 , 2 , 3]
             """,
      expected: """
                let numA = [1, 2, 3]
                let numB = [1, 2, 3]
                let numC = [1, 2, 3]
                """)
  }
  
  #if !os(macOS)
  static let allTests = [
    CommaWhitespaceTests.testInvalidFuncCommaWhiteSpace,
    CommaWhitespaceTests.testInvalidDeclCommaWhiteSpace,
    ]
  #endif
}
