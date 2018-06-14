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
    
    var modifierIterator = modifiers.makeIterator()
    if let accessKeyword = modifierIterator.next() {

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
        diagnose(.removeRedundantAccessKeyword(name: node.extendedType.description), on: accessKeyword)
        return node.withModifiers(removeModifier(curModifiers: modifiers, removal: accessKeyword))
                .withExtensionKeyword(node.extensionKeyword.withOneLeadingNewline())
      default:
        return node
      }
    }
    return node
  }
  
  // Returns modifier list without the access modifier
  func removeModifier(curModifiers: ModifierListSyntax, removal: DeclModifierSyntax) -> ModifierListSyntax {
    var newMods: [DeclModifierSyntax] = []
    for modifier in curModifiers {
      if modifier.name != removal.name {
        newMods.append(modifier)
      }
    }
    return SyntaxFactory.makeModifierList(newMods)
  }
  
  // Adds given keyword to all members in declaration block
  func addMemberAccessKeywords(memDeclBlock: MemberDeclBlockSyntax, keyword: DeclModifierSyntax) -> MemberDeclListSyntax {
    var newMembers: [MemberDeclListItemSyntax] = []
    let formattedKeyword = keyword.withName(keyword.name.withLeadingTrivia(.newlines(1) + .spaces(2)))
    
    for member in memDeclBlock.members {
      
      if let varDecl = member.decl as? VariableDeclSyntax {
        // Check for modifiers, if none, put accessor keyword before var/let keyword
        guard let modifiers = varDecl.modifiers
          else {
            let formattedVarDecl = varDecl.withLetOrVarKeyword(varDecl.letOrVarKeyword.withoutLeadingTrivia())
            newMembers.append(member.withDecl(formattedVarDecl.addModifier(formattedKeyword)))
            continue
          }
        // If variable already has an accessor keyword, skip (do not overwrite)
        guard hasAccessorKeyword(modifiers: modifiers) == false
          else { newMembers.append(member); continue }
        // Put accessor keyword before the first modifier keyword in the declaration
        if let next = modifiers.first {
          let formattedNext = next.withName(next.name.withoutLeadingTrivia())
          let newDecl = varDecl.withModifiers(modifiers.replacing(childAt: next.indexInParent, with: formattedNext).prepending(formattedKeyword))
          newMembers.append(member.withDecl(newDecl))
        }
      
      } else if let funcDecl = member.decl as? FunctionDeclSyntax {
        guard let modifiers = funcDecl.modifiers
          else {
            let formattedFuncDecl = funcDecl.withFuncKeyword(funcDecl.funcKeyword.withoutLeadingTrivia())
            newMembers.append(member.withDecl(formattedFuncDecl.addModifier(formattedKeyword)))
            continue
        }
        guard hasAccessorKeyword(modifiers: modifiers) == false
          else { newMembers.append(member); continue }
        
        if let next = modifiers.first {
          let formattedNext = next.withName(next.name.withoutLeadingTrivia())
          let newDecl = funcDecl.withModifiers(modifiers.replacing(childAt: next.indexInParent, with: formattedNext).prepending(formattedKeyword))
          newMembers.append(member.withDecl(newDecl))
        }
      
        
        // TODO(laurenwhite)
      } else if let associatedTypeDecl = member.decl as? AssociatedtypeDeclSyntax {
        let formattedAssociateDecl = associatedTypeDecl.withAssociatedtypeKeyword(associatedTypeDecl.associatedtypeKeyword.withoutLeadingTrivia())
        newMembers.append(member.withDecl(formattedAssociateDecl.addModifier(formattedKeyword)))
      
      } else if let classDecl = member.decl as? ClassDeclSyntax {
        let formattedClassDecl = classDecl.withClassKeyword(classDecl.classKeyword.withoutLeadingTrivia())
        newMembers.append(member.withDecl(formattedClassDecl.addModifier(formattedKeyword)))
      
      } else if let enumDecl = member.decl as? EnumDeclSyntax {
        let formattedEnumDecl = enumDecl.withEnumKeyword(enumDecl.enumKeyword.withoutLeadingTrivia())
        newMembers.append(member.withDecl(formattedEnumDecl.addModifier(formattedKeyword)))
      
      } else if let protocolDecl = member.decl as? ProtocolDeclSyntax {
        let formattedProtocolDecl = protocolDecl.withProtocolKeyword(protocolDecl.protocolKeyword.withoutLeadingTrivia())
        newMembers.append(member.withDecl(formattedProtocolDecl.addModifier(formattedKeyword)))
      
      } else if let structDecl = member.decl as? StructDeclSyntax {
        let formattedStructDecl = structDecl.withStructKeyword(structDecl.structKeyword.withoutLeadingTrivia())
        newMembers.append(member.withDecl(formattedStructDecl.addModifier(formattedKeyword)))
      
      } else if let typeAliasDecl = member.decl as? TypealiasDeclSyntax {
        let formattedAliasDecl = typeAliasDecl.withTypealiasKeyword(typeAliasDecl.typealiasKeyword.withoutLeadingTrivia())
        newMembers.append(member.withDecl(formattedAliasDecl.addModifier(formattedKeyword)))
      
      } else if let initDecl = member.decl as? InitializerDeclSyntax {
        let formattedInitDecl = initDecl.withInitKeyword(initDecl.initKeyword.withoutLeadingTrivia())
        newMembers.append(member.withDecl(formattedInitDecl.addModifier(formattedKeyword)))
      }
    }
    return SyntaxFactory.makeMemberDeclList(newMembers)
  }
  
  // Determines if declaration already contains an access keyword
  func hasAccessorKeyword(modifiers: ModifierListSyntax) -> Bool {
    for modifier in modifiers {
      let keywordKind = modifier.name.tokenKind
      switch keywordKind {
      case .publicKeyword, .privateKeyword, .fileprivateKeyword, .internalKeyword:
        return true
      default:
        continue
      }
    }
    return false
  }
}


extension Diagnostic.Message {
  static func removeRedundantAccessKeyword(name: String) -> Diagnostic.Message {
    return .init(.warning, "Remove redundant 'internal' access keyword from \(name)")
  }
  
  static func moveAccessKeyword(keyword: String) -> Diagnostic.Message {
    return .init(.warning, "Specify \(keyword) access level for each member inside the extension")
  }
}
