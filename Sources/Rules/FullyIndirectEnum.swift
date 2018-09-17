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

/// If all cases of an enum are `indirect`, the entire enum should be marked `indirect`.
///
/// Lint: If every case of an enum is `indirect`, but the enum itself is not, a lint error is
///       raised.
///
/// Format: Enums where all cases are `indirect` will be rewritten such that the enum is marked
///         `indirect`, and each case is not.
///
/// - SeeAlso: https://google.github.io/swift#enum-cases
public final class FullyIndirectEnum: SyntaxFormatRule {

  public override func visit(_ node: EnumDeclSyntax) -> DeclSyntax {
    let enumMembers = node.members.members
    guard allAreIndirectCases(members: enumMembers) else { return node }
    diagnose(.reassignIndirectKeyword(name: node.identifier.text), on: node.identifier)

    // Removes 'indirect' keyword from cases, reformats
    var newMembers: [DeclSyntax] = []
    for member in enumMembers {
      if let caseMember = member as? EnumCaseDeclSyntax {
        guard let caseModifiers = caseMember.modifiers else { continue }
        guard let firstModifier = caseModifiers.first else { continue }
        let newCase = caseMember.withModifiers(caseModifiers.remove(name: "indirect"))
        let formattedCase = formatCase(unformattedCase: newCase,
                                       leadingTrivia: firstModifier.leadingTrivia)
        newMembers.append(formattedCase)
      } else {
        newMembers.append(member)
      }
    }

    let newMemberBlock = SyntaxFactory.makeMemberDeclBlock(
      leftBrace: node.members.leftBrace,
      members: SyntaxFactory.makeDeclList(newMembers),
      rightBrace: node.members.rightBrace)

    // Format indirect keyword and following token, if necessary
    guard let firstTok = node.firstToken else { return node }
    var leadingTrivia: Trivia = []
    var newDecl = node
    if firstTok.tokenKind == .enumKeyword {
      leadingTrivia = firstTok.leadingTrivia
      newDecl = replaceTrivia(on: node,
                              token: node.firstToken,
                              leadingTrivia: []) as! EnumDeclSyntax
    }

    let newModifier = SyntaxFactory.makeDeclModifier(
                      name: SyntaxFactory.makeIdentifier("indirect",
                                                         leadingTrivia: leadingTrivia,
                                                         trailingTrivia: .spaces(1)),
                      detail: nil)

    return newDecl.addModifier(newModifier).withMembers(newMemberBlock)
  }

  // Determines if all given cases are indirect
  func allAreIndirectCases(members: DeclListSyntax) -> Bool {
    for member in members {
      if let caseMember = member as? EnumCaseDeclSyntax {
        guard let caseModifiers = caseMember.modifiers else { return false }
        if caseModifiers.has(modifier: "indirect") { continue }
        else { return false }
      }
    }
    return true
  }

  // Transfers given leading trivia to the first token in the case declaration
  func formatCase(unformattedCase: EnumCaseDeclSyntax,
                  leadingTrivia: Trivia?) -> EnumCaseDeclSyntax {
    if let modifiers = unformattedCase.modifiers, let first = modifiers.first {
      return replaceTrivia(on: unformattedCase,
                           token: first.firstToken,
                           leadingTrivia: leadingTrivia) as! EnumCaseDeclSyntax
    } else {
      return replaceTrivia(on: unformattedCase,
                           token: unformattedCase.caseKeyword,
                           leadingTrivia: leadingTrivia) as! EnumCaseDeclSyntax
    }
  }
}

extension Diagnostic.Message {
  static func reassignIndirectKeyword(name: String) -> Diagnostic.Message {
    return .init(.warning, "move 'indirect' to \(name) enum declaration")
  }
}
