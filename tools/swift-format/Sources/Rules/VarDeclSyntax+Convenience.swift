import SwiftSyntax

extension VariableDeclSyntax {

  /// Returns array of all identifiers listed in the declaration.
  var identifiers: [IdentifierPatternSyntax] {
    var ids: [IdentifierPatternSyntax] = []
    for binding in bindings {
      guard let id = binding.pattern as? IdentifierPatternSyntax else { continue }
      ids.append(id)
    }
    return ids
  }

  /// Returns the first identifier.
  var firstIdentifier: IdentifierPatternSyntax {
    return identifiers[0]
  }

  /// Returns the first type explicitly stated in the declaration, if present.
  var firstType: TypeSyntax? {
    return bindings.first?.typeAnnotation?.type
  }

  /// Returns the first initializer clause, if present.
  var firstInitializer: InitializerClauseSyntax? {
    return bindings.first?.initializer
  }
}
