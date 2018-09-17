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
  public override func visit(_ node: SourceFileSyntax) {
    setImportsXCTest(context: context, sourceFile: node)
    super.visit(node)
  }

  public override func visit(_ node: VariableDeclSyntax) {
    guard !context.importsXCTest else { return }
    // Ignores IBOutlet variables
    if let attributes = node.attributes {
      for attribute in attributes {
        if attribute.attributeName.text == "IBOutlet" { return }
      }
    }
    // Finds type annotation for variable(s)
    for binding in node.bindings {
      guard let nodeTypeAnnotation = binding.typeAnnotation else { continue }
      diagnoseImplicitWrapViolation(nodeTypeAnnotation.type)
    }
  }

  func diagnoseImplicitWrapViolation(_ type: TypeSyntax) {
    guard let violation = type as? ImplicitlyUnwrappedOptionalTypeSyntax else { return }
    diagnose(.doNotUseImplicitUnwrapping(identifier: "\(violation.wrappedType)"), on: type)
  }
}

extension Diagnostic.Message {
  static func doNotUseImplicitUnwrapping(identifier: String) -> Diagnostic.Message {
    return .init(.warning, "use \(identifier) or \(identifier)? instead of \(identifier)!")
  }
}
