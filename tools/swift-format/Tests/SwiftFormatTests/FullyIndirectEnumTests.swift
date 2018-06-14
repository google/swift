import Foundation
import XCTest
import SwiftSyntax

@testable import Rules

public class FullyIndirectEnumTests: DiagnosingTestCase {
  public func testIndirectEnumReassignment() {
    XCTAssertFormatting(
      FullyIndirectEnum.self,
      input: """
             public enum DependencyGraphNode {
               internal indirect case userDefined(dependencies: [DependencyGraphNode])
               indirect case synthesized(dependencies: [DependencyGraphNode])
               indirect case other(dependencies: [DependencyGraphNode])
               var x: Int
             }
             public enum CompassPoint {
               case north
               indirect case south
               case east
               case west
             }
             """,
      expected: """
                public indirect enum DependencyGraphNode {
                  internal case userDefined(dependencies: [DependencyGraphNode])
                  case synthesized(dependencies: [DependencyGraphNode])
                  case other(dependencies: [DependencyGraphNode])
                  var x: Int
                }
                public enum CompassPoint {
                  case north
                  indirect case south
                  case east
                  case west
                }
                """
    )
  }
}
