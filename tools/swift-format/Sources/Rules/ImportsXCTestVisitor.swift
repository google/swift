import Core
import Foundation
import SwiftSyntax

/// Visitor that determines if the target source file imports XCTest
private final class ImportsXCTestVisitor: SyntaxVisitor {
  let context: Context
  
  init(context: Context) {
    self.context = context
  }

  override func visit(_ node: SourceFileSyntax) {
    for statement in node.statements {
      guard let importDecl = statement.item as? ImportDeclSyntax else { continue }
      for component in importDecl.path {
        guard component.name.text == "XCTest" else { continue }
        context.importsXCTest = true
        context.didSetImportsXCTest = true
        return
      }
    }
    context.didSetImportsXCTest = true
  }
}

/// Sets the appropriate value of the importsXCTest field in the Context class, which
/// indicates whether the file contains test code or not.
///
/// This setter will only run the visitor if another rule hasn't already called this function to
/// determine if the source file imports XCTest.
///
/// - Parameters:
///   - context: The context information of the target source file.
///   - sourceFile: The file to be visited.
func setImportsXCTest(context: Context, sourceFile: SourceFileSyntax) {
  guard !context.didSetImportsXCTest else { return }
  ImportsXCTestVisitor(context: context).visit(sourceFile)
}
