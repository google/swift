import Core
import Foundation
import SwiftSyntax

/// Overloads with only a closure argument should not be disambiguated by parameter labels.
///
/// Lint: If two overloaded functions with one closure parameter appear in the same scope, a lint
///       error is raised.
///
/// - SeeAlso: https://google.github.io/swift#trailing-closures
public final class AmbiguousTrailingClosureOverload: SyntaxLintRule {
  func diagnoseBadOverloads(_ overloads: [String: [FunctionDeclSyntax]]) {
    for (_, decls) in overloads where decls.count > 1 {
      let decl = decls[0]
      diagnose(.ambiguousTrailingClosureOverload(decl.fullDeclName), on: decl.identifier) {
        for decl in decls.dropFirst() {
          $0.note(
            .otherAmbiguousOverloadHere(decl.fullDeclName),
            location: decl.identifier.startLocation(in: self.context.fileURL)
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
      guard params.count == 1 else { continue }
      let firstParam = params[0]
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

  public override func visit(_ node: SourceFileSyntax) {
    let functions = node.statements.compactMap { $0.item as? FunctionDeclSyntax }
    discoverAndDiagnoseOverloads(functions)
    super.visit(node)
  }

  public override func visit(_ node: CodeBlockSyntax) {
    let functions = node.statements.compactMap { $0.item as? FunctionDeclSyntax }
    discoverAndDiagnoseOverloads(functions)
    super.visit(node)
  }

  public override func visit(_ decls: MemberDeclBlockSyntax) {
    let functions = decls.members.compactMap { $0 as? FunctionDeclSyntax }
    discoverAndDiagnoseOverloads(functions)
    super.visit(decls)
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
