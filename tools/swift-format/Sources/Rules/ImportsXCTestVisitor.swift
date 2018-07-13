import Core
import Foundation
import SwiftSyntax

private final class ImportsXCTestVisitor: SyntaxVisitor {
  
  let context: Context
  
  public init(context: Context) {
    self.context = context
  }
  
  override func visit(_ node: SourceFileSyntax) {
    for statement in node.statements {
      print(statement.item)
      guard let importDecl = statement.item as? ImportDeclSyntax else { continue }
      for component in importDecl.path {
        guard component.name.text == "XCTest" else { continue }
        context.importsXCTest = true
        return
      }
    }
  }
}

func setImportsXCTest(context: Context, sourceFile: SourceFileSyntax) {
  ImportsXCTestVisitor(context: context).visit(sourceFile)
}
