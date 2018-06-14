import Core
import Foundation
import SwiftSyntax

/// Identifiers should not have leading underscores.
///
/// This is intended to avoid certain antipatterns; `self.member = member` should be preferred to
/// `member = _member` and the leading underscore should not be used to signal access level.
///
/// Lint: Declaring an identifier with a leading underscore yields a lint error.
///
/// - SeeAlso: https://google.github.io/swift#naming-conventions-are-not-access-control
public final class NoLeadingUnderscores: SyntaxLintRule {
  
  public override func visit(_ node: AssociatedtypeDeclSyntax) {
    diagnoseUnderscoreViolation(name: node.identifier)
  }
  
  public override func visit(_ node: ClassDeclSyntax) {
    diagnoseUnderscoreViolation(name: node.identifier)
    super.visit(node) // Visit children despite override
  }
  
  public override func visit(_ node: EnumDeclSyntax) {
    diagnoseUnderscoreViolation(name: node.identifier)
    super.visit(node)
  }
  
  public override func visit(_ node: EnumCaseDeclSyntax) {
    var iterator = node.elements.makeIterator()
    while let item = iterator.next() {
      diagnoseUnderscoreViolation(name: item.identifier)
    }
  }
  
  public override func visit(_ node: FunctionDeclSyntax) {
    diagnoseUnderscoreViolation(name: node.identifier)
    // Check parameter names of function
    var paramIterator = node.signature.input.parameterList.makeIterator()
    while let parameter = paramIterator.next() {
      if let typeIdentifier = parameter.firstName {
        diagnoseUnderscoreViolation(name: typeIdentifier)
      }
      if let varIdentifier = parameter.secondName {
        diagnoseUnderscoreViolation(name: varIdentifier)
      }
    }
    // Check generic parameter names
    var genParamIterator = node.genericParameterClause?.genericParameterList.makeIterator()
    while let genParamter = genParamIterator?.next() {
      diagnoseUnderscoreViolation(name: genParamter.name)
    }
    super.visit(node)
  }
  
  public override func visit(_ node: PrecedenceGroupDeclSyntax) {
    diagnoseUnderscoreViolation(name: node.identifier)
  }
  
  public override func visit(_ node: ProtocolDeclSyntax) {
    diagnoseUnderscoreViolation(name: node.identifier)
    super.visit(node)
  }
  
  public override func visit(_ node: StructDeclSyntax) {
    diagnoseUnderscoreViolation(name: node.identifier)
    // Check generic parameter names
    var iterator = node.genericParameterClause?.genericParameterList.makeIterator()
    while let genParam = iterator?.next() {
        diagnoseUnderscoreViolation(name: genParam.name)
    }
    super.visit(node)
  }
  
  public override func visit(_ node: TypealiasDeclSyntax) {
    diagnoseUnderscoreViolation(name: node.identifier)
  }
  
  public override func visit(_ node: InitializerDeclSyntax) {
    // Check parameter names of initializer
    var iterator = node.parameters.parameterList.makeIterator()
    while let parameter = iterator.next() {
      if let typeIdentifier = parameter.firstName {
        diagnoseUnderscoreViolation(name: typeIdentifier)
      }
      if let varIdentifier = parameter.secondName {
        diagnoseUnderscoreViolation(name: varIdentifier)
      }
    }
    super.visit(node)
  }
  
  public override func visit(_ node: VariableDeclSyntax) {
    for binding in node.bindings {
      if let pat = binding.pattern as? IdentifierPatternSyntax {
        diagnoseUnderscoreViolation(name: pat.identifier)
      }
    }
    super.visit(node)
  }
  
  func diagnoseUnderscoreViolation(name: TokenSyntax) {
    let leadingChar = name.text.first
    if leadingChar == "_" {
      diagnose(.doNotLeadWithUnderscore(identifier: name.text), on: name)
    }
  }
}

extension Diagnostic.Message {
  static func doNotLeadWithUnderscore(identifier: String) -> Diagnostic.Message {
    return .init(.warning, "Identifier \(identifier) should not lead with '_'")
  }
}
