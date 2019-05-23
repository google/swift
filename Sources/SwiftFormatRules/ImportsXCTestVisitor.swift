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

/// Visitor that determines if the target source file imports XCTest
private struct ImportsXCTestVisitor: SyntaxVisitor {
  let context: Context

  init(context: Context) {
    self.context = context
  }

  mutating func visit(_ node: SourceFileSyntax) -> SyntaxVisitorContinueKind {
    for statement in node.statements {
      guard let importDecl = statement.item as? ImportDeclSyntax else { continue }
      for component in importDecl.path {
        guard component.name.text == "XCTest" else { continue }
        context.importsXCTest = true
        context.didSetImportsXCTest = true
        return .skipChildren
      }
    }
    context.didSetImportsXCTest = true
    return .skipChildren
  }
}

/// Sets the appropriate value of the importsXCTest field in the Context class, which
/// indicates whether the file contains test code or not.
///
/// This setter will only run the visitor if another rule hasn't already called this function to
/// determine if the source file imports XCTest.
///
/// - Parameters:
///   - context: The context information of the target source file.
///   - sourceFile: The file to be visited.
func setImportsXCTest(context: Context, sourceFile: SourceFileSyntax) {
  guard !context.didSetImportsXCTest else { return }
  var visitor = ImportsXCTestVisitor(context: context)
  sourceFile.walk(&visitor)
}
