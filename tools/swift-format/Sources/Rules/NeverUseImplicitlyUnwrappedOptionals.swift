import Core
import Foundation
import SwiftSyntax

/// Implicitly unwrapped optionals (e.g. `var s: String!`) are forbidden.
///
/// Certain properties (e.g. `@IBOutlet`) tied to the UI lifecycle are ignored.
///
/// This rule does not apply to test code, defined as code which:
///   * Contains the line `import XCTest`
///
/// TODO: Create exceptions for other UI elements (ex: viewDidLoad)
///
/// Lint: Declaring a property with an implicitly unwrapped type yields a lint error.
///
/// - SeeAlso: https://google.github.io/swift#implicitly-unwrapped-optionals
public final class NeverUseImplicitlyUnwrappedOptionals: SyntaxLintRule {
  
  // Checks if "XCTest" is an import statement
  public override func visit(_ node: ImportDeclSyntax) {
    var iterator = node.path.makeIterator()
    while let component = iterator.next() {
      if component.name.text == "XCTest" {
        context.importsXCTest = true
      }
    }
  }

  public override func visit(_ node: VariableDeclSyntax) {
    if !context.importsXCTest {
      // Ignores IBOutlet variables
      if let attributes = node.attributes {
        var iterator = attributes.makeIterator()
        while let item = iterator.next() {
          if item.attributeName.text == "IBOutlet" { return }
        }
      }
      // Finds type annotation for variable(s)
      for binding in node.bindings {
        guard let nodeTypeAnnotation = binding.typeAnnotation else { continue }
        diagnoseImplicitWrapViolation(nodeTypeAnnotation.type)
      }
    }
  }

  func diagnoseImplicitWrapViolation(_ type: TypeSyntax) {
    guard let violation = type as? ImplicitlyUnwrappedOptionalTypeSyntax else { return }
    diagnose(.doNotUseImplicitUnwrapping(identifier: "\(violation.wrappedType)"), on: type)
  }
}

extension Diagnostic.Message {
  static func doNotUseImplicitUnwrapping(identifier: String) -> Diagnostic.Message {
    return .init(.warning, "Use \(identifier) or \(identifier)? instead of \(identifier)!")
  }
}
