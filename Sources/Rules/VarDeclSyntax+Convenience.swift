//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Formatter open source project.
//
// Copyright (c) 2018 Apple Inc. and the Swift Formatter project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Swift Formatter project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

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
