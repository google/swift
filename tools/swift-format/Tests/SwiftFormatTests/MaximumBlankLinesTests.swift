import Foundation
import XCTest
import SwiftSyntax

@testable import Rules

public class MaximumBlankLinesTests: DiagnosingTestCase {
  public func testInvalidMaximumBlankLines() {
    XCTAssertFormatting(
      MaximumBlankLines.self,
      input: """


             /// Doc Comment

             import Foundation
             let a = 1
             let b = 2



             // Multiline


             // comment for b


             var b = 12

             // eof


             """,
      expected: """

                /// Doc Comment

                import Foundation
                let a = 1
                let b = 2

                // Multiline

                // comment for b

                var b = 12
                
                // eof


                """)
  }
  
  public func testInvalidWithMemberTypesMaximumBlankLines() {
    XCTAssertFormatting(
      MaximumBlankLines.self,
      input: """

             struct foo {
               let a = 1


               let b = 2
               var isTest: Bool {



                 return true


               }
             
             }



             struct test {}


             """,
      expected: """

                struct foo {
                  let a = 1


                  let b = 2
                  var isTest: Bool {

                    return true

                  }

                }

                struct test {}
                

                """)
  }
  
  public func testIgnoreMultilineStrings() {
    XCTAssertFormatting(
      MaximumBlankLines.self,
      input: """
             // Blanklines in multiline string
             // should be ignored.
             let a = 1

             
             let strMulti = \"""
                            This is a multiline
                            
                            
                            string
                            \"""
             """,
      expected: """
                // Blanklines in multiline string
                // should be ignored.
                let a = 1

                let strMulti = \"""
                               This is a multiline
                               
                               
                               string
                               \"""
                """)
  }
  
  #if !os(macOS)
  static let allTests = [
    MaximumBlankLinesTests.testInvalidBlankMaximumBlankLines,
    MaximumBlankLinesTests.testInvalidWithMemberTypesMaximumBlankLines,
    MaximumBlankLinesTests.testIgnoreMultilineStrings,
    
    ]
  #endif
}
