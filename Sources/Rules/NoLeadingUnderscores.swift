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

/// Identifiers in declarations and patterns should not have leading underscores.
///
/// This is intended to avoid certain antipatterns; `self.member = member` should be preferred to
/// `member = _member` and the leading underscore should not be used to signal access level.
///
/// This rule intentionally checks only the parameter variable names of a function declaration, not
/// the parameter labels. It also only checks identifiers at the declaration site, not at usage
/// sites.
///
/// Lint: Declaring an identifier with a leading underscore yields a lint error.
///
/// - SeeAlso: https://google.github.io/swift#naming-conventions-are-not-access-control
public final class NoLeadingUnderscores: SyntaxLintRule {

  public override func visit(_ node: AssociatedtypeDeclSyntax) {
    diagnoseIfNameStartsWithUnderscore(node.identifier)
    super.visit(node)
  }

  public override func visit(_ node: ClassDeclSyntax) {
    diagnoseIfNameStartsWithUnderscore(node.identifier)
    super.visit(node)
  }

  public override func visit(_ node: EnumCaseElementSyntax) {
    diagnoseIfNameStartsWithUnderscore(node.identifier)
    super.visit(node)
  }

  public override func visit(_ node: EnumDeclSyntax) {
    diagnoseIfNameStartsWithUnderscore(node.identifier)
    super.visit(node)
  }

  public override func visit(_ node: FunctionDeclSyntax) {
    diagnoseIfNameStartsWithUnderscore(node.identifier)
    super.visit(node)
  }

  public override func visit(_ node: FunctionParameterSyntax) {
    // If both names are provided, we want to check `secondName`, which will be the parameter name
    // (in that case, `firstName` is the label). If only one name is present, then it is recorded in
    // `firstName`, and it is both the label and the parameter name.
    if let variableIdentifier = node.secondName ?? node.firstName {
      diagnoseIfNameStartsWithUnderscore(variableIdentifier)
    }
    super.visit(node)
  }

  public override func visit(_ node: GenericParameterSyntax) {
    diagnoseIfNameStartsWithUnderscore(node.name)
    super.visit(node)
  }

  public override func visit(_ node: IdentifierPatternSyntax) {
    diagnoseIfNameStartsWithUnderscore(node.identifier)
    super.visit(node)
  }

  public override func visit(_ node: PrecedenceGroupDeclSyntax) {
    diagnoseIfNameStartsWithUnderscore(node.identifier)
    super.visit(node)
  }

  public override func visit(_ node: ProtocolDeclSyntax) {
    diagnoseIfNameStartsWithUnderscore(node.identifier)
    super.visit(node)
  }

  public override func visit(_ node: StructDeclSyntax) {
    diagnoseIfNameStartsWithUnderscore(node.identifier)
    super.visit(node)
  }

  public override func visit(_ node: TypealiasDeclSyntax) {
    diagnoseIfNameStartsWithUnderscore(node.identifier)
    super.visit(node)
  }

  /// Checks the given token to determine if it begins with an underscore (but is not *just* an
  /// underscore, which is allowed), emitting a diagnostic if it does.
  ///
  /// - Parameter token: The token to check.
  private func diagnoseIfNameStartsWithUnderscore(_ token: TokenSyntax) {
    let text = token.text
    if text.count > 1 && text.first == "_" {
      diagnose(.doNotStartWithUnderscore(identifier: text), on: token)
    }
  }
}

extension Diagnostic.Message {

  static func doNotStartWithUnderscore(identifier: String) -> Diagnostic.Message {
    return .init(.warning, "identifier \(identifier) should not start with '_'")
  }
}
