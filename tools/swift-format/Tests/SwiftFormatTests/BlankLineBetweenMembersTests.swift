import Foundation
import XCTest
import SwiftSyntax

@testable import Rules

public class BlankLineBetweenMembersTests: DiagnosingTestCase {
  public func testInvalidBlankLineBetweenMembers() {
    XCTAssertFormatting(
      BlankLineBetweenMembers.self,
      input: """
             struct foo1 {
               var test1 = 13
               // Multiline
               // comment for b
               var b = 12


               /*BlockComment*/
               var c = 11




               // Multiline comment
               // for d
               var d: Bool {
               return false
               }
               /// Comment for e
               var end1: Bool {
               return false
               }
             }
             """,
      expected: """
                struct foo1 {
                  var test1 = 13
                  // Multiline
                  // comment for b
                  var b = 12

                  /*BlockComment*/
                  var c = 11

                  // Multiline comment
                  // for d
                  var d: Bool {
                  return false
                  }

                  /// Comment for e
                  var end1: Bool {
                  return false
                  }
                }
                """)
  }
  
  public func testTwoMembers() {
    XCTAssertFormatting(
      BlankLineBetweenMembers.self,
      input: """
             struct foo2 {
               var test2 = 13

               var a = 10
             }

             struct secondFoo2 {
               var a = 1
               var end2: Bool {
               return false
               }
             }
             """,
      expected: """
                struct foo2 {
                  var test2 = 13

                  var a = 10
                }

                struct secondFoo2 {
                  var a = 1

                  var end2: Bool {
                  return false
                  }
                }
                """)
  }
  
  public func testNestedMembers() {
    XCTAssertFormatting(
      BlankLineBetweenMembers.self,
      input: """
             struct foo3 {
               // nested Rank enumeration
               enum Rank: Int {
                 case two = 2, three, four


                 case jack, queen, king, ace
               }



               struct secondFoo3 {
                 var a = 1
                 var e: Bool {
                 return false
                 }
               }
             }
             """,
      expected: """
                struct foo3 {
                  // nested Rank enumeration
                  enum Rank: Int {
                    case two = 2, three, four

                    case jack, queen, king, ace
                  }

                  struct secondFoo3 {
                    var a = 1

                    var e: Bool {
                    return false
                    }
                  }
                }
                """)
  }
  
  #if !os(macOS)
  static let allTests = [
    BlankLineBetweenMembersTests.testInvalidBlankLineBetweenMembers,
    BlankLineBetweenMembersTests.testTwoMembers,
    BlankLineBetweenMembersTests.testNestedMembers,

    ]
  #endif
}
