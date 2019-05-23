//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2018 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import Foundation
import SwiftFormatCore
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
public struct NeverUseImplicitlyUnwrappedOptionals: SyntaxLintRule {

  public let context: Context

  public init(context: Context) {
    self.context = context
  }

  // Checks if "XCTest" is an import statement
  public func visit(_ node: SourceFileSyntax) -> SyntaxVisitorContinueKind {
    setImportsXCTest(context: context, sourceFile: node)
    return .visitChildren
  }

  public func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
    guard !context.importsXCTest else { return .skipChildren }
    // Ignores IBOutlet variables
    if let attributes = node.attributes {
      for attribute in attributes {
        if (attribute as? AttributeSyntax)?.attributeName.text == "IBOutlet" {
          return .skipChildren
        }
      }
    }
    // Finds type annotation for variable(s)
    for binding in node.bindings {
      guard let nodeTypeAnnotation = binding.typeAnnotation else { continue }
      diagnoseImplicitWrapViolation(nodeTypeAnnotation.type)
    }
    return .skipChildren
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
