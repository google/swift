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

/// Manages a registry of lint rules to apply to specific kinds of nodes.
public final class LintPipeline: SyntaxVisitor, Pipeline {
  private let context: Context

  /// Creates a Pipeline with the provided Context and Mode.
  ///
  /// - Parameter context: The context in which to execute all of these passes.
  public init(context: Context) {
    self.context = context
  }

  /// A list of file-based Syntax rules.
  private var fileRules = [FileRule]()

  /// A mapping between syntax types and closures that will perform linting operations over them.
  private var passMap = [SyntaxType: [(Syntax) -> Void]]()

  /// Adds a file-based rule to be run before format rules.
  ///
  /// - Parameter fileRule: The file-based lint rule metatype that will be run before any other
  ///                       formatting/lint rules.
  public func addFileRule(_ fileRule: FileRule.Type) {
    fileRules.append(fileRule.init(context: context))
  }

  /// Adds a given linter to the registry of passes, to be run over Syntax nodes of the provided
  /// types.
  ///
  /// - Parameters
  ///   - lintType: The metatype of the linter to be added, e.g. `AlwaysUseLowerCamelCase.self`
  ///   - syntaxTypes: The list of syntax metatypes to apply format operations to.
  public func addLinter(_ lintRule: SyntaxLintRule.Type, for syntaxTypes: Syntax.Type...) {
    for type in syntaxTypes {
      let rule = lintRule.init(context: context)
      passMap[SyntaxType(type: type), default: []].append(rule.visit)
    }
  }

  /// Adds a given formatter to the registry of passes to run over nodes of the provided types.
  /// These formatters will have their formatting results thrown away during linting.
  ///
  /// - Parameters
  ///   - formatType: The metatype of the formatter to be added, e.g. `ColonWhitespace.self`
  ///   - syntaxTypes: The list of syntax metatypes to apply format operations to.
  public func addFormatter(_ formatRule: SyntaxFormatRule.Type, for syntaxTypes: Syntax.Type...) {
    for type in syntaxTypes {
      let rule = formatRule.init(context: context)
      passMap[SyntaxType(type: type), default: []].append {
        _ = rule.visit($0)
      }
    }
  }

  public override func visitPre(_ node: Syntax) {
    let syntaxType = SyntaxType(type: type(of: node))
    guard let passes = passMap[syntaxType] else { return }
    for pass in passes {
      pass(node)
    }
  }
}

