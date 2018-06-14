import Core
import Foundation
import SwiftSyntax

/// Force-try (`try!`) is forbidden.
///
/// This rule does not apply to test code, defined as code which:
///   * Contains the line `import XCTest`
///
/// Lint: Using `try!` results in a lint error.
///
/// TODO: Create exception for NSRegularExpression
///
/// - SeeAlso: https://google.github.io/swift#error-types
public final class NeverUseForceTry: SyntaxLintRule {
  
  // Checks if "XCTest" is an import statement
  public override func visit(_ node: ImportDeclSyntax) {
    var iterator = node.path.makeIterator()
    while let component = iterator.next() {
      if component.name.text == "XCTest" {
        context.importsXCTest = true
      }
    }
  }
  
  public override func visit(_ node: TryExprSyntax) {
    if !context.importsXCTest {
      guard let mark = node.questionOrExclamationMark else { return }
      if mark.tokenKind == .exclamationMark {
        diagnose(.doNotForceTry, on: node.tryKeyword)
      }
    }
  }
}

extension Diagnostic.Message {
  static let doNotForceTry = Diagnostic.Message(.warning, "Do not use force try")
}
