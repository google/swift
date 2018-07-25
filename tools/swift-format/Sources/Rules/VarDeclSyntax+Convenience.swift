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
  var identifier: IdentifierPatternSyntax {
    return identifiers[0]
  }

  /// Returns the type of the variable, if explicitly stated in the declaration.
  var type: TypeSyntax? {
    for binding in bindings {
      guard let typeAnnotation = binding.typeAnnotation else { continue }
      return typeAnnotation.type
    }
    return nil
  }

  /// Returns the initializer clause, if present.
  var initializer: InitializerClauseSyntax? {
    for binding in bindings {
      guard let initializer = binding.initializer else { continue }
      return initializer
    }
    return nil
  }
}
