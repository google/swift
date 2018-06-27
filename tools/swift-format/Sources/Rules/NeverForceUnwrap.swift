import Core
import SwiftSyntax

/// Force-unwraps are strongly discouraged and must be documented.
///
/// Lint: If a force unwrap is used, a lint warning is raised.
///       TODO(abl): consider having documentation (e.g. a comment) cancel the warning?
///
/// - SeeAlso: https://google.github.io/swift#force-unwrapping-and-force-casts
public final class NeverForceUnwrap: SyntaxLintRule {
  
  // Checks if "XCTest" is an import statement
  public override func visit(_ node: ImportDeclSyntax) {
    var iterator = node.path.makeIterator()
    while let component = iterator.next() {
      if component.name.text == "XCTest" {
        context.importsXCTest = true
      }
    }
  }
  
  public override func visit(_ node: ForcedValueExprSyntax) {
    guard !context.importsXCTest else { return }
    diagnose(.doNotForceUnwrap(name: node.expression.description), on: node)
  }
  
  public override func visit(_ node: AsExprSyntax) {
    guard !context.importsXCTest else { return }
    diagnose(.doNotForceCast(name: node.typeName.description), on: node)
  }
}

extension Diagnostic.Message {
  static func doNotForceUnwrap(name: String) -> Diagnostic.Message {
    return .init(.warning, "Do not force unwrap '\(name)'")
  }
  static func doNotForceCast(name: String) -> Diagnostic.Message {
    return .init(.warning, "Do not force cast to '\(name)'")
  }
}
