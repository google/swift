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

  public override func visit(_ node: SourceFileSyntax) {
    setImportsXCTest(context: context, sourceFile: node)
    super.visit(node)
  }

  public override func visit(_ node: TryExprSyntax) {
    guard !context.importsXCTest else { return }
    guard let mark = node.questionOrExclamationMark else { return }
    if mark.tokenKind == .exclamationMark {
      diagnose(.doNotForceTry, on: node.tryKeyword)
    }
  }
}

extension Diagnostic.Message {
  static let doNotForceTry = Diagnostic.Message(.warning, "do not use force try")
}
