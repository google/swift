import Core
import Foundation
import SwiftSyntax

/// Use caseless `enum`s for namespacing.
///
/// In practice, this means that any `class` or `struct` that consists of only `static let`s and
/// `static func`s should be converted to an `enum`.
///
/// Lint: `class`es or `struct`s consisting of only `static let/func`s will yield a lint error.
///
/// Format: Rewrite the `class` or `struct` as an `enum`.
///         TODO(abl): This can get complicated to pattern-match correctly.
// .        TODO(b/78286392): Give this formatting pass a category that makes it not run on save.
///
/// - SeeAlso: https://google.github.io/swift#nesting-and-namespacing
public final class UseEnumForNamespacing: SyntaxFormatRule {
  public override func visit(_ node: StructDeclSyntax) -> DeclSyntax {
    guard let newDecls = declsIfUsedAsNamespace(node.members.members),
          node.genericParameterClause == nil,
          node.inheritanceClause == nil else {
      return node
    }

    diagnose(.convertToEnum(kind: "struct", name: node.identifier), on: node)

    return makeEnum(
      declarationKeyword: node.structKeyword,
      modifiers: node.modifiers,
      name: node.identifier,
      members: node.members.withMembers(newDecls)
    )
  }
  public override func visit(_ node: ClassDeclSyntax) -> DeclSyntax {
    guard let newDecls = declsIfUsedAsNamespace(node.members.members),
          node.genericParameterClause == nil,
          node.inheritanceClause == nil else {
      return node
    }

    diagnose(.convertToEnum(kind: "class", name: node.identifier), on: node)

    return makeEnum(
      declarationKeyword: node.classKeyword,
      modifiers: node.modifiers,
      name: node.identifier,
      members: node.members.withMembers(newDecls)
    )
  }

  func makeEnum(
    declarationKeyword: TokenSyntax,
    modifiers: ModifierListSyntax?,
    name: TokenSyntax,
    members: MemberDeclBlockSyntax
  ) -> EnumDeclSyntax {
    return EnumDeclSyntax {
      if let mods = modifiers {
        for mod in mods { $0.addModifier(mod) }
      }
      $0.useEnumKeyword(declarationKeyword.withKind(.enumKeyword))
      $0.useIdentifier(name)
      $0.useMembers(members)
    }
  }

  /// Determines if the set of declarations is consistent with a class or struct being used
  /// solely as a namespace for static functions. If there is a non-static private initializer
  /// with no arguments, that does not count against possibly being a namespace.
  func declsIfUsedAsNamespace(_ members: DeclListSyntax) -> DeclListSyntax? {
    if members.count == 0 { return nil }
    var declList = [DeclSyntax]()
    for member in members {
      switch member {
      case let decl as FunctionDeclSyntax:
        guard let modifiers = decl.modifiers,
              modifiers.has(modifier: "static") else {
          return nil
        }
        declList.append(member)
      case let decl as VariableDeclSyntax:
        guard let modifiers = decl.modifiers,
              modifiers.has(modifier: "static") else {
          return nil
        }
        declList.append(member)
      case let decl as InitializerDeclSyntax:
        guard let modifiers = decl.modifiers,
              modifiers.has(modifier: "private"),
              decl.parameters.parameterList.count == 0 else {
          return nil
        }
        // Do not append private initializer
      default:
        declList.append(member)
      }
    }
    return SyntaxFactory.makeDeclList(declList)
  }
}

extension Diagnostic.Message {
  static func convertToEnum(kind: String, name: TokenSyntax) -> Diagnostic.Message {
    return .init(
      .warning,
      "\(kind) '\(name.text)' used as a namespace should be an enum"
    )
  }
}
