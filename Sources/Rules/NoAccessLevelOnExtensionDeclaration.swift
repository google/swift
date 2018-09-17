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

/// Specifying an access level for an extension declaration is forbidden.
///
/// Lint: Specifying an access level for an extension declaration yields a lint error.
///
/// Format: The access level is removed from the extension declaration and is added to each
///         declaration in the extension; declarations with redundant access levels (e.g.
///         `internal`, as that is the default access level) have the explicit access level removed.
///
/// TODO: Find a better way to access modifiers and keyword tokens besides casting each declaration
///
/// - SeeAlso: https://google.github.io/swift#access-levels
public final class NoAccessLevelOnExtensionDeclaration: SyntaxFormatRule {

  public override func visit(_ node: ExtensionDeclSyntax) -> DeclSyntax {
    guard let modifiers = node.modifiers, modifiers.count != 0 else { return node }
    guard let accessKeyword = modifiers.accessLevelModifier else { return node }

    let keywordKind = accessKeyword.name.tokenKind
    switch keywordKind {
    // Public, private, or fileprivate keywords need to be moved to members
    case .publicKeyword, .privateKeyword, .fileprivateKeyword:
      diagnose(.moveAccessKeyword(keyword: accessKeyword.name.text), on: accessKeyword)
      let newMembers = SyntaxFactory.makeMemberDeclBlock(
        leftBrace: node.members.leftBrace,
        members: addMemberAccessKeywords(memDeclBlock: node.members, keyword: accessKeyword),
        rightBrace: node.members.rightBrace)
      return node.withMembers(newMembers)
              .withModifiers(modifiers.remove(name: accessKeyword.name.text))
    // Internal keyword redundant, delete
    case .internalKeyword:
      diagnose(.removeRedundantAccessKeyword(name: node.extendedType.description),
               on: accessKeyword)
      let newKeyword = replaceTrivia(on: node.extensionKeyword,
                                     token: node.extensionKeyword,
                                     leadingTrivia: accessKeyword.leadingTrivia) as! TokenSyntax
      return node.withModifiers(modifiers.remove(name: accessKeyword.name.text))
              .withExtensionKeyword(newKeyword)
    default:
      break
    }
    return node
  }

  // Adds given keyword to all members in declaration block
  func addMemberAccessKeywords(memDeclBlock: MemberDeclBlockSyntax,
                               keyword: DeclModifierSyntax) -> DeclListSyntax {
    var newMembers: [DeclSyntax] = []
    
    for member in memDeclBlock.members {
      guard let firstTokInDecl = member.firstToken else { continue }
      let formattedKeyword = replaceTrivia(on: keyword,
                                           token: keyword.name,
                                           leadingTrivia: firstTokInDecl.leadingTrivia)
                                           as! DeclModifierSyntax

      guard let newMember = addModifier(declaration: member, modifierKeyword: formattedKeyword)
        as? DeclSyntax else { continue }
      newMembers.append(newMember)
    }
    return SyntaxFactory.makeDeclList(newMembers)
  }
}

extension Diagnostic.Message {
  static func removeRedundantAccessKeyword(name: String) -> Diagnostic.Message {
    return .init(.warning, "remove redundant 'internal' access keyword from \(name)")
  }
  
  static func moveAccessKeyword(keyword: String) -> Diagnostic.Message {
    return .init(.warning, "specify \(keyword) access level for each member inside the extension")
  }
}
