import Foundation
import XCTest
import SwiftSyntax

@testable import Rules

public class NoAccessLevelOnExtensionDeclarationTests: DiagnosingTestCase {
  public func testExtensionDeclarationAccessLevel() {
    XCTAssertFormatting(
      NoAccessLevelOnExtensionDeclaration.self,
      input: """
             public extension Foo {
               var x: Bool
               // Comment 1
               internal var y: Bool
               // Comment 2
               static var z: Bool
               static func someFunc() {}
               init() {}
               protocol SomeProtocol {}
               class SomeClass {}
               struct SomeStruct {}
               enum SomeEnum {}
             }
             internal extension Bar {
               var a: Int
               var b: Int
             }
             """,
      expected: """
                extension Foo {
                  public var x: Bool
                  // Comment 1
                  internal var y: Bool
                  // Comment 2
                  public static var z: Bool
                  public static func someFunc() {}
                  public init() {}
                  public protocol SomeProtocol {}
                  public class SomeClass {}
                  public struct SomeStruct {}
                  public enum SomeEnum {}
                }
                extension Bar {
                  var a: Int
                  var b: Int
                }
                """
    )
  }

#if !os(macOS)
static let allTests = [
  NoAccessLevelOnExtensionDeclarationTests.testExtensionDeclarationAccessLevel,
  ]
#endif
}
