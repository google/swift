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

    for accessKeyword in modifiers {

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
                .withModifiers(removeModifier(curModifiers: modifiers, removal: accessKeyword))
      // Internal keyword redundant, delete
      case .internalKeyword:
        diagnose(.removeRedundantAccessKeyword(name: node.extendedType.description),
                 on: accessKeyword)
        let newKeyword = replaceTrivia(on: node.extensionKeyword,
                                       token: node.extensionKeyword,
                                       leadingTrivia: accessKeyword.leadingTrivia) as! TokenSyntax
        return node.withModifiers(removeModifier(curModifiers: modifiers, removal: accessKeyword))
                .withExtensionKeyword(newKeyword)
      default:
        return node
      }
    }
    return node
  }

  // Returns modifier list without the access modifier
  func removeModifier(curModifiers: ModifierListSyntax,
                      removal: DeclModifierSyntax) -> ModifierListSyntax {
    var newMods: [DeclModifierSyntax] = []
    for modifier in curModifiers {
      if modifier.name != removal.name {
        newMods.append(modifier)
      }
    }
    return SyntaxFactory.makeModifierList(newMods)
  }

  // Adds given keyword to all members in declaration block
  func addMemberAccessKeywords(memDeclBlock: MemberDeclBlockSyntax,
                               keyword: DeclModifierSyntax) -> MemberDeclListSyntax {
    var newMembers: [MemberDeclListItemSyntax] = []
    
    for member in memDeclBlock.members {
      guard let firstTokInDecl = member.firstToken else { continue }
      let formattedKeyword = replaceTrivia(on: keyword,
                                           token: keyword.name,
                                           leadingTrivia: firstTokInDecl.leadingTrivia)
                                           as! DeclModifierSyntax

      guard let newMember = addModifier(declaration: member, modifierKeyword: formattedKeyword)
        as? MemberDeclListItemSyntax else { continue }
      newMembers.append(newMember)
    }
    return SyntaxFactory.makeMemberDeclList(newMembers)
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
