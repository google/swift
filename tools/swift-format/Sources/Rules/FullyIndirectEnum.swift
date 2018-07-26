
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
    var newMembers: [MemberDeclListItemSyntax] = []
    for member in enumMembers {
      if let caseMember = member.decl as? EnumCaseDeclSyntax {
        guard let caseModifiers = caseMember.modifiers else { continue }
        guard let firstModifier = caseModifiers.first else { continue }
        let newCase = caseMember.withModifiers(removeIndirectModifier(curModifiers: caseModifiers))
        let formattedCase = formatCase(unformattedCase: newCase,
                                       leadingTrivia: firstModifier.leadingTrivia)
        let newMember = SyntaxFactory.makeMemberDeclListItem(decl: formattedCase, semicolon: nil)
        newMembers.append(newMember)
      } else {
        newMembers.append(member)
      }
    }

    let members = SyntaxFactory.makeMemberDeclList(newMembers)
    let newMemberBlock = SyntaxFactory.makeMemberDeclBlock(leftBrace: node.members.leftBrace,
                                                           members: members,
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
                      detailLeftParen: nil, detail: nil, detailRightParen: nil)

    return newDecl.addModifier(newModifier).withMembers(newMemberBlock)
  }

  // Determines if all given cases are indirect
  func allAreIndirectCases(members: MemberDeclListSyntax) -> Bool {
    for member in members {
      if let caseMember = member.decl as? EnumCaseDeclSyntax {
        guard let caseModifiers = caseMember.modifiers else { return false }
        if isIndirectCase(modifiers: caseModifiers) { continue }
        else { return false }
      }
    }
    return true
  }

  func isIndirectCase(modifiers: ModifierListSyntax) -> Bool {
    for modifier in modifiers {
      if modifier.name.tokenKind == .identifier("indirect") { return true }
    }
    return false
  }

  func removeIndirectModifier(curModifiers: ModifierListSyntax) -> ModifierListSyntax {
    var newMods: [DeclModifierSyntax] = []
      for modifier in curModifiers {
        if modifier.name.tokenKind != .identifier("indirect") { newMods.append(modifier) }
      }
    return SyntaxFactory.makeModifierList(newMods)
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
