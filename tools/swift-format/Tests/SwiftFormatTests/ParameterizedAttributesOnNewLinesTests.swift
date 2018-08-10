import Foundation
import XCTest
import SwiftSyntax

@testable import Rules

public class ParameterizedAttributesOnNewLinesTests: DiagnosingTestCase {
  public func testInvalidParameterizedAttributeList() {
    XCTAssertFormatting(
      ParameterizedAttributesOnNewLines.self,
      input: """


             // Comment 1
             @objc(someFeature)
             @available(swift 3.0.2)

             // Comment 2.0

             // Comment 2.1


             // Comment 2.2
             @available(iOS 9.0, *)
             public func someFeature() {
               print("Reorder")
             }

             /// Comment 3 - doc comment
             @available(swift 3.0.2)
             // Comment 4
             @available(iOS 9.0, *) @objc(otherFeature) public func otherFeature() {
               print("New lines and reorder")
               // Comment 5
               @available(iOS 9.0, *) func subFeature() {
                 print("Nested")
               }
             }

             @objc @available(iOS 9.0, *) public func lastFeature() {
               print("With unparameterized attributes")
             }
             """,
      expected: """


                // Comment 2.0
                // Comment 2.1
                // Comment 2.2
                @available(iOS 9.0, *)
                @available(swift 3.0.2)
                // Comment 1
                @objc(someFeature)
                public func someFeature() {
                  print("Reorder")
                }

                /// Comment 3 - doc comment
                // Comment 4
                @available(iOS 9.0, *)
                @available(swift 3.0.2)
                @objc(otherFeature)
                public func otherFeature() {
                  print("New lines and reorder")
                  // Comment 5
                  @available(iOS 9.0, *)
                  func subFeature() {
                    print("Nested")
                  }
                }

                @available(iOS 9.0, *)
                @objc public func lastFeature() {
                  print("With unparameterized attributes")
                }
                """)
  }
  
  #if !os(macOS)
  static let allTests = [
    ParameterizedAttributesOnNewLinesTests.testInvalidParameterizedAttributeList,
    ]
  #endif
}
