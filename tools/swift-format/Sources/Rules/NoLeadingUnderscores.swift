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
    for element in node.elements {
      diagnoseUnderscoreViolation(name: element.identifier)
    }
  }
  
  public override func visit(_ node: FunctionDeclSyntax) {
    diagnoseUnderscoreViolation(name: node.identifier)
    // Check parameter names of function
    let parameters = node.signature.input.parameterList
    for parameter in parameters {
      if let typeIdentifier = parameter.firstName {
        diagnoseUnderscoreViolation(name: typeIdentifier)
      }
      if let varIdentifier = parameter.secondName {
        diagnoseUnderscoreViolation(name: varIdentifier)
      }
    }
    // Check generic parameter names
    if let genParameters = node.genericParameterClause?.genericParameterList {
      for genParameter in genParameters {
        diagnoseUnderscoreViolation(name: genParameter.name)
      }
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
    if let genParameters = node.genericParameterClause?.genericParameterList {
      for genParameter in genParameters {
        diagnoseUnderscoreViolation(name: genParameter.name)
      }
    }
    super.visit(node)
  }
  
  public override func visit(_ node: TypealiasDeclSyntax) {
    diagnoseUnderscoreViolation(name: node.identifier)
  }
  
  public override func visit(_ node: InitializerDeclSyntax) {
    // Check parameter names of initializer
    let parameters = node.parameters.parameterList
    for parameter in parameters {
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
