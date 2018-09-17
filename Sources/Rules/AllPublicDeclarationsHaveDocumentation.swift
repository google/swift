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

/// All public or open declarations must have a top-level documentation comment.
///
/// Lint: If a public declaration is missing a documentation comment, a lint error is raised.
///
/// - SeeAlso: https://google.github.io/swift#where-to-document
public final class AllPublicDeclarationsHaveDocumentation: SyntaxLintRule {
  override public func visit(_ node: FunctionDeclSyntax) {
    diagnoseMissingDocComment(node, name: node.fullDeclName, modifiers: node.modifiers)
  }

  override public func visit(_ node: InitializerDeclSyntax) {
    diagnoseMissingDocComment(node, name: "init", modifiers: node.modifiers)
  }

  override public func visit(_ node: DeinitializerDeclSyntax) {
    diagnoseMissingDocComment(node, name: "deinit", modifiers: node.modifiers)
  }

  override public func visit(_ node: SubscriptDeclSyntax) {
    diagnoseMissingDocComment(node, name: "subscript", modifiers: node.modifiers)
  }

  override public func visit(_ node: ClassDeclSyntax) {
    diagnoseMissingDocComment(node, name: node.identifier.text, modifiers: node.modifiers)
  }

  override public func visit(_ node: VariableDeclSyntax) {
    guard node.bindings.count == 1 else { return }
    let mainBinding = node.bindings[0]
    diagnoseMissingDocComment(node, name: "\(mainBinding.pattern)", modifiers: node.modifiers)
  }

  override public func visit(_ node: StructDeclSyntax) {
    diagnoseMissingDocComment(node, name: node.identifier.text, modifiers: node.modifiers)
  }

  override public func visit(_ node: ProtocolDeclSyntax) {
    diagnoseMissingDocComment(node, name: node.identifier.text, modifiers: node.modifiers)
  }

  override public func visit(_ node: TypealiasDeclSyntax) {
    diagnoseMissingDocComment(node, name: node.identifier.text, modifiers: node.modifiers)
  }

  func diagnoseMissingDocComment(
    _ decl: DeclSyntax,
    name: String,
    modifiers: ModifierListSyntax?
  ) {
    guard decl.docComment == nil else { return }
    guard let mods = modifiers,
          mods.has(modifier: "public"),
          !mods.has(modifier: "override") else {
      return
    }

    diagnose(.declRequiresComment(name), on: decl)
  }
}

extension Diagnostic.Message {
  static func declRequiresComment(_ name: String) -> Diagnostic.Message {
    return .init(.warning, "add a documentation comment for '\(name)'")
  }
}
