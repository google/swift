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

/// Return `Void`, not `()`, in signatures.
///
/// Note that this rule does *not* apply to function declaration signatures in order to avoid
/// conflicting with `NoVoidReturnOnFunctionSignature`.
///
/// Lint: Returning `()` in a signature yields a lint error.
///
/// Format: `-> ()` is replaced with `-> Void`
///
/// - SeeAlso: https://google.github.io/swift#types-with-shorthand-names
public final class ReturnVoidInsteadOfEmptyTuple: SyntaxFormatRule {
  public override func visit(_ node: FunctionTypeSyntax) -> TypeSyntax {
    guard let returnType = node.returnType as? TupleTypeSyntax,
      returnType.elements.count == 0 else { return node }
    diagnose(.returnVoid, on: node.returnType)
    let voidKeyword =  SyntaxFactory.makeSimpleTypeIdentifier(
      name: SyntaxFactory.makeIdentifier(
        "Void",
        trailingTrivia: returnType.rightParen.trailingTrivia),
      genericArgumentClause: nil)
    return node.withReturnType(voidKeyword)
  }
}

extension Diagnostic.Message {
  static let returnVoid = Diagnostic.Message(.warning, "replace '()' with 'Void'")
}
