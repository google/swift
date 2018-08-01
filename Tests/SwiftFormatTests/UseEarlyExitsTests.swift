import Foundation
import XCTest
import SwiftSyntax

@testable import Rules

public class UseEarlyExitsTests: DiagnosingTestCase {
  public func testIfToGuardStmtSwitch() {
    // The indentation in the expected output is explicitly incorrect because this formatting rule
    // does not fix it up with the assumption that the pretty-printer will handle it.
    XCTAssertFormatting(
      UseEarlyExits.self,
      input: """
             func discombobulate(_ values: [Int]) throws -> Int {

               // Comment 1

               /*Comment 2*/ if let first = values.first {
                 // Comment 3

                 /// Doc comment
                 if first >= 0 {
                   // Comment 4
                   var result = 0
                   for value in values {
                     result += invertedCombobulatoryFactor(of: value)
                   }
                   return result
                 } else {
                   print("Can't have negative energy")
                   throw DiscombobulationError.negativeEnergy
                 }
               } else {
                 print("The array was empty")
                 throw DiscombobulationError.arrayWasEmpty
               }
             }
             """,
      expected: """
                func discombobulate(_ values: [Int]) throws -> Int {

                  // Comment 1

                  /*Comment 2*/ guard let first = values.first else {
                    print("The array was empty")
                    throw DiscombobulationError.arrayWasEmpty
                  }
                    // Comment 3

                    /// Doc comment
                    guard first >= 0 else {
                      print("Can't have negative energy")
                      throw DiscombobulationError.negativeEnergy
                    }
                      // Comment 4
                      var result = 0
                      for value in values {
                        result += invertedCombobulatoryFactor(of: value)
                      }
                      return result
                }
                """)
    
  }
  
  #if !os(macOS)
  static let allTests = [
    UseEarlyExitsTests.testSwitchStmts,
    ]
  #endif

}
