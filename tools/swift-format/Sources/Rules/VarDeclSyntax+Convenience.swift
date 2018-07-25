import SwiftSyntax

extension VariableDeclSyntax {

  var identifiers: [IdentifierPatternSyntax] {
    var ids: [IdentifierPatternSyntax] = []
    for binding in bindings {
      guard let id = binding.pattern as? IdentifierPatternSyntax else { continue }
      ids.append(id)
    }
    return ids
  }
}
