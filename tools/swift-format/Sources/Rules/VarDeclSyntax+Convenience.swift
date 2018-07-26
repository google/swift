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
    for binding in bindings {
      guard let typeAnnotation = binding.typeAnnotation else { continue }
      return typeAnnotation.type
    }
    return nil
  }

  /// Returns the first initializer clause, if present.
  var firstInitializer: InitializerClauseSyntax? {
    for binding in bindings {
      guard let initializer = binding.initializer else { continue }
      return initializer
    }
    return nil
  }
}
