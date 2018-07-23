import Core
import Foundation
import SwiftSyntax

/// Function calls should never mix normal closure arguments and trailing closures.
///
/// Lint: If a function call with a trailing closure also contains a non-trailing closure argument,
///       a lint error is raised.
///
/// - SeeAlso: https://google.github.io/swift#trailing-closures
public final class OnlyOneTrailingClosureArgument: SyntaxLintRule {

  public override func visit(_ node: FunctionCallExprSyntax) {
    guard (node.argumentList.contains { $0.expression is ClosureExprSyntax }) else { return }
    guard node.trailingClosure != nil else { return }
    diagnose(.removeTrailingClosure, on: node)
  }
}

extension Diagnostic.Message {
  static let removeTrailingClosure =
    Diagnostic.Message(.warning,
                      "function call shouldn't have both closure arguments and a trailing closure")
}
