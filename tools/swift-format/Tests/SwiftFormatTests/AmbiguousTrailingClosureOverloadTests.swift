import Foundation
import SwiftSyntax
import XCTest

@testable import Rules

public class AmbiguousTrailingClosureOverloadTests: DiagnosingTestCase {
  public func testAmbiguousOverloads() {
    performLint(
      AmbiguousTrailingClosureOverload.self,
      input: """
             func strong(mad: () -> Int) {}
             func strong(bad: (Bool) -> Bool) {}
             func strong(sad: (String) -> Bool) {}

             class A {
               static func the(cheat: (Int) -> Void) {}
               class func the(sneak: (Int) -> Void) {}
               func the(kingOfTown: () -> Void) {}
               func the(cheatCommandos: (Bool) -> Void) {}
               func the(brothersStrong: (String) -> Void) {}
             }

             struct B {
               func hom(estar: () -> Int) {}
               func hom(sar: () -> Bool) {}

               static func baleeted(_ f: () -> Void) {}
               func baleeted(_ f: () -> Void) {}
             }
             """
    )

    XCTAssertDiagnosed(.ambiguousTrailingClosureOverload("strong(mad:)"))
    XCTAssertDiagnosed(.otherAmbiguousOverloadHere("strong(bad:)"))
    XCTAssertDiagnosed(.otherAmbiguousOverloadHere("strong(sad:)"))

    XCTAssertDiagnosed(.ambiguousTrailingClosureOverload("the(cheat:)"))
    XCTAssertDiagnosed(.otherAmbiguousOverloadHere("the(sneak:)"))

    XCTAssertDiagnosed(.ambiguousTrailingClosureOverload("the(kingOfTown:)"))
    XCTAssertDiagnosed(.otherAmbiguousOverloadHere("the(cheatCommandos:)"))
    XCTAssertDiagnosed(.otherAmbiguousOverloadHere("the(brothersStrong:)"))

    XCTAssertDiagnosed(.ambiguousTrailingClosureOverload("hom(estar:)"))
    XCTAssertDiagnosed(.otherAmbiguousOverloadHere("hom(sar:)"))

    XCTAssertNotDiagnosed(.ambiguousTrailingClosureOverload("baleeted(_:)"))
    XCTAssertNotDiagnosed(.otherAmbiguousOverloadHere("baleeted(_:)"))
  }

#if !os(macOS)
  static let allTests = [
    AmbiguousTrailingClosureOverloadTests.testAmbiguousOverloads,
  ]
#endif
}
