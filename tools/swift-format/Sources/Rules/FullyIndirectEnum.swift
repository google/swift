
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
    
    // Verifies all cases are indirect
    var it = node.members.members.makeIterator()
    while let caseMember = it.next()?.decl as? EnumCaseDeclSyntax {
      guard let caseModifiers = caseMember.modifiers else { return node }
      if isIndirectCase(modifiers: caseModifiers) { continue }
      else { return node }
    }
    diagnose(.reassignIndirectKeyword(name: node.identifier.text), on: node.identifier)
    
    // Removes 'internal' keyword from cases, reformats
    var newMembers: [MemberDeclListItemSyntax] = []
    for member in enumMembers {
      if let caseMember = member.decl as? EnumCaseDeclSyntax {
        guard let caseModifiers = caseMember.modifiers else { continue }
        let newCase = caseMember.withModifiers(removeInternalModifier(curModifiers: caseModifiers))
        let formattedCase = formatCase(unformattedCase: newCase)
        let newMember = SyntaxFactory.makeMemberDeclListItem(decl: formattedCase, semicolon: nil)
        newMembers.append(newMember)
      } else {
        newMembers.append(member)
      }
    }

    let newMemberBlock = SyntaxFactory.makeMemberDeclBlock(leftBrace: SyntaxFactory.makeLeftBraceToken(),
                                                           members: SyntaxFactory.makeMemberDeclList(newMembers),
                                                           rightBrace: SyntaxFactory.makeRightBraceToken().withOneLeadingNewline())
    
    let newEnumDecl = node.addModifier(SyntaxFactory.makeDeclModifier(name: SyntaxFactory.makeIdentifier("indirect").withOneTrailingSpace(), detailLeftParen: nil, detail: nil, detailRightParen: nil)).withMembers(newMemberBlock)
    return newEnumDecl
  }
  
  func isIndirectCase(modifiers: ModifierListSyntax) -> Bool {
        for modifier in modifiers {
          if modifier.name.tokenKind == .identifier("indirect") {  return true }
        }
        return false
    }
  
  func removeInternalModifier(curModifiers: ModifierListSyntax) -> ModifierListSyntax {
    var newMods: [DeclModifierSyntax] = []
      for modifier in curModifiers {
        if modifier.name.tokenKind != .identifier("indirect") { newMods.append(modifier) }
      }
    return SyntaxFactory.makeModifierList(newMods)
  }
  
  // Puts new line and indentation in front of the first keyword in the declaration
  func formatCase(unformattedCase: EnumCaseDeclSyntax) -> EnumCaseDeclSyntax {
    if let modifiers = unformattedCase.modifiers, let first = modifiers.first {
      return unformattedCase.withModifiers(modifiers.replacing(childAt: first.indexInParent, with: first.withName(first.name.withLeadingTrivia(.newlines(1) + .spaces(2)))))
    } else {
      return unformattedCase.withCaseKeyword(unformattedCase.caseKeyword.withLeadingTrivia(.newlines(1) + .spaces(2)))
    }
  }
}

extension Diagnostic.Message {
  static func reassignIndirectKeyword(name: String) -> Diagnostic.Message {
    return .init(.warning, "Move 'indirect' to \(name) enum declaration")
  }
}
