import Foundation
import XCTest
import SwiftSyntax

@testable import Rules

public class CaseIndentLevelEqualsSwitchTests: DiagnosingTestCase {
  public func testsInvalidCaseIndent() {
    XCTAssertFormatting(
      CaseIndentLevelEqualsSwitch.self,
      input: """
             switch order {
              
             case .ascending:
               print("Ascending")
                          case .descending:
               print("Descending")
                case .same:
               print("Same")
             }
             """,
      expected: """
                switch order {
                
                case .ascending:
                  print("Ascending")
                case .descending:
                  print("Descending")
                case .same:
                  print("Same")
                }
                """)
  }
  
  public func testsInvalidCaseIndent2() {
    XCTAssertFormatting(
      CaseIndentLevelEqualsSwitch.self,
      input: """
             if true {
               switch order {
             case .ascending:
                 print("Ascending")
                          case .descending:
                 print("Descending")
                case .same:
                 print("Same")
               }
             }
             """,
      expected: """
                if true {
                  switch order {
                  case .ascending:
                    print("Ascending")
                  case .descending:
                    print("Descending")
                  case .same:
                    print("Same")
                  }
                }
                """)
  }
  
  #if !os(macOS)
  static let allTests = [
    CaseIndentLevelEqualsSwitchTests.testSemicolonUse,
    ]
  #endif
  
}
