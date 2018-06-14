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
               internal var y: Bool
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
                  internal var y: Bool
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
