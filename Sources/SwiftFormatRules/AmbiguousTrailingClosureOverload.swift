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

/// Overloads with only a closure argument should not be disambiguated by parameter labels.
///
/// Lint: If two overloaded functions with one closure parameter appear in the same scope, a lint
///       error is raised.
///
/// - SeeAlso: https://google.github.io/swift#trailing-closures
public struct AmbiguousTrailingClosureOverload: SyntaxLintRule {
  public let context: Context

  public init(context: Context) {
    self.context = context
  }

  func diagnoseBadOverloads(_ overloads: [String: [FunctionDeclSyntax]]) {
    for (_, decls) in overloads where decls.count > 1 {
      let decl = decls[0]
      diagnose(.ambiguousTrailingClosureOverload(decl.fullDeclName), on: decl.identifier) {
        for decl in decls.dropFirst() {
          $0.note(
            .otherAmbiguousOverloadHere(decl.fullDeclName),
            location: decl.identifier.startLocation(converter: self.context.sourceLocationConverter)
          )
        }
      }
    }
  }

  func discoverAndDiagnoseOverloads(_ functions: [FunctionDeclSyntax]) {
    var overloads = [String: [FunctionDeclSyntax]]()
    var staticOverloads = [String: [FunctionDeclSyntax]]()
    for fn in functions {
      let params = fn.signature.input.parameterList
      guard let firstParam = params.firstAndOnly else { continue }
      guard firstParam.type is FunctionTypeSyntax else { continue }
      if let mods = fn.modifiers, mods.has(modifier: "static") || mods.has(modifier: "class") {
        staticOverloads[fn.identifier.text, default: []].append(fn)
      } else {
        overloads[fn.identifier.text, default: []].append(fn)
      }
    }

    diagnoseBadOverloads(overloads)
    diagnoseBadOverloads(staticOverloads)
  }

  public func visit(_ node: SourceFileSyntax) -> SyntaxVisitorContinueKind {
    let functions = node.statements.compactMap { $0.item as? FunctionDeclSyntax }
    discoverAndDiagnoseOverloads(functions)
    return .visitChildren
  }

  public func visit(_ node: CodeBlockSyntax) -> SyntaxVisitorContinueKind {
    let functions = node.statements.compactMap { $0.item as? FunctionDeclSyntax }
    discoverAndDiagnoseOverloads(functions)
    return .visitChildren
  }

  public func visit(_ decls: MemberDeclBlockSyntax) -> SyntaxVisitorContinueKind {
    let functions = decls.members.compactMap { $0.decl as? FunctionDeclSyntax }
    discoverAndDiagnoseOverloads(functions)
    return .visitChildren
  }
}

extension Diagnostic.Message {
  static func ambiguousTrailingClosureOverload(_ decl: String) -> Diagnostic.Message {
    return .init(.warning, "rename '\(decl)' so it is no longer ambiguous with a trailing closure")
  }
  static func otherAmbiguousOverloadHere(_ decl: String) -> Diagnostic.Message {
    return .init(.note, "ambiguous overload '\(decl)' is here")
  }
}
