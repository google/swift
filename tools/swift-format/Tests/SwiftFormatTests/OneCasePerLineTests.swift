import Foundation
import XCTest
import SwiftSyntax

@testable import Rules

public class OneCasePerLineTests: DiagnosingTestCase {
  func testInvalidCasesOnLine() {
    XCTAssertFormatting(OneCasePerLine.self,
                        input: """
                               public enum Token {
                                 case arrow
                                 case comma, identifier(String), semicolon, stringSegment(String)
                                 case period
                                 indirect case guardKeyword, elseKeyword, contextualKeyword(String)
                                 var x: Bool
                                 case leftParen, rightParen = ")", leftBrace, rightBrace = "}"
                               }
                               """,
                        expected: """
                                  public enum Token {
                                    case arrow
                                    case comma, semicolon
                                    case identifier(String)
                                    case stringSegment(String)
                                    case period
                                    indirect case guardKeyword, elseKeyword
                                    indirect case contextualKeyword(String)
                                    var x: Bool
                                    case leftParen, leftBrace
                                    case rightParen = ")"
                                    case rightBrace = "}"
                                  }
                                  """)
  }
  
  #if !os(macOS)
  static let allTests = [
    OneCasePerLineTests.testInvalidCasesOnLine,
    ]
  #endif
}
