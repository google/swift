import SwiftSyntax
import XCTest

@testable import Rules

public class OrderedImportsTests: DiagnosingTestCase {
  public func testInvalidImportsOrder() {
    XCTAssertFormatting(
      OrderedImports.self,
      input: """
             import Foundation
             // Starts Imports
             import Core


             // Comment with new lines
             import UIKit

             @testable import Rules
             import enum Darwin.D.isatty
             // Starts Test
             @testable import MyModuleUnderTest
             // Starts Ind
             import func Darwin.C.isatty

             let a = 3
             import SwiftSyntax
             """,
      expected: """
                // Starts Imports
                import Core
                import Foundation
                import SwiftSyntax
                // Comment with new lines
                import UIKit
                
                // Starts Ind
                import func Darwin.C.isatty
                import enum Darwin.D.isatty

                // Starts Test
                @testable import MyModuleUnderTest
                @testable import Rules

                let a = 3
                """)
  }
  
  public func testImportsOrderWithoutModuleType() {
    XCTAssertFormatting(
      OrderedImports.self,
      input: """
             @testable import Rules
             import func Darwin.D.isatty
             @testable import MyModuleUnderTest
             import func Darwin.C.isatty

             let a = 3
             """,
      expected: """
                import func Darwin.C.isatty
                import func Darwin.D.isatty

                @testable import MyModuleUnderTest
                @testable import Rules

                let a = 3
                """)
  }
  
  public func testImportsOrderWithDocComment() {
    XCTAssertFormatting(
      OrderedImports.self,
      input: """
             /// Test imports with comments.
             ///
             /// Comments at the top of the file
             /// should be preserved.

             // Line comment for import
             // Foundation.
             import Foundation
             // Line comment for Core
             import Core
             import UIKit

             let a = 3
             """,
      expected: """
                /// Test imports with comments.
                ///
                /// Comments at the top of the file
                /// should be preserved.

                // Line comment for Core
                import Core
                // Line comment for import
                // Foundation.
                import Foundation
                import UIKit

                let a = 3
                """)
  }
  
  public func testValidOrderedImport() {
    XCTAssertFormatting(
      OrderedImports.self,
      input: """
             import CoreLocation
             import MyThirdPartyModule
             import SpriteKit
             import UIKit

             import func Darwin.C.isatty

             @testable import MyModuleUnderTest
             """,
      expected: """
                import CoreLocation
                import MyThirdPartyModule
                import SpriteKit
                import UIKit

                import func Darwin.C.isatty

                @testable import MyModuleUnderTest
                """)
  }
  #if !os(macOS)
  static let allTests = [
    OrderedImportsTests.testInvalidImportsOrder,
    OrderedImportsTests.testImportsOrderWithoutModuleType,
    OrderedImportsTests.testImportsOrderWithDocComment,
    OrderedImportsTests.testValidOrderedImport
    ]
  #endif
}
