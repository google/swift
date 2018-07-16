import Core
import Foundation
import SwiftSyntax

private final class AddModifierRewriter: SyntaxRewriter {
  let modifierKeyword: DeclModifierSyntax

  init(modifierKeyword: DeclModifierSyntax) {
    self.modifierKeyword = modifierKeyword
  }

  override func visit(_ node: VariableDeclSyntax) -> DeclSyntax {
    // Check for modifiers, if none, put accessor keyword before var/let keyword
    guard let modifiers = node.modifiers else {
      let formattedVarDecl = replaceTrivia(on: node,
                                           token: node.letOrVarKeyword,
                                           leadingTrivia: .spaces(0)) as! VariableDeclSyntax
      return formattedVarDecl.addModifier(modifierKeyword)
    }
    // If variable already has an accessor keyword, skip (do not overwrite)
    guard !hasAccessorKeyword(modifiers: modifiers) else { return node }

    // Put accessor keyword before the first modifier keyword in the declaration
    let newModifiers = insertAccessorKeyword(curModifiers: modifiers)
    return node.withModifiers(newModifiers)
  }

  override func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
    guard let modifiers = node.modifiers else {
      let formattedFuncDecl = replaceTrivia(on: node,
                                           token: node.funcKeyword,
                                           leadingTrivia: .spaces(0)) as! FunctionDeclSyntax
      return formattedFuncDecl.addModifier(modifierKeyword)
    }

    guard !hasAccessorKeyword(modifiers: modifiers) else { return node }
    
    let newModifiers = insertAccessorKeyword(curModifiers: modifiers)
    return node.withModifiers(newModifiers)
  }

  override func visit(_ node: AssociatedtypeDeclSyntax) -> DeclSyntax {
    guard let modifiers = node.modifiers else {
      let formattedAssociateDecl = replaceTrivia(on: node,
                                           token: node.associatedtypeKeyword,
                                           leadingTrivia: .spaces(0)) as! AssociatedtypeDeclSyntax
      return formattedAssociateDecl.addModifier(modifierKeyword)
    }
    
    guard !hasAccessorKeyword(modifiers: modifiers) else { return node }
    
    let newModifiers = insertAccessorKeyword(curModifiers: modifiers)
    return node.withModifiers(newModifiers)
  }

  override func visit(_ node: ClassDeclSyntax) -> DeclSyntax {
    guard let modifiers = node.modifiers else {
      let formattedClassDecl = replaceTrivia(on: node,
                                           token: node.classKeyword,
                                           leadingTrivia: .spaces(0)) as! ClassDeclSyntax
      return formattedClassDecl.addModifier(modifierKeyword)
    }

    guard !hasAccessorKeyword(modifiers: modifiers) else { return node }

    let newModifiers = insertAccessorKeyword(curModifiers: modifiers)
    return node.withModifiers(newModifiers)
  }

  override func visit(_ node: EnumDeclSyntax) -> DeclSyntax {
    guard let modifiers = node.modifiers else {
      let formattedEnumDecl = replaceTrivia(on: node,
                                             token: node.enumKeyword,
                                             leadingTrivia: .spaces(0)) as! EnumDeclSyntax
      return formattedEnumDecl.addModifier(modifierKeyword)
    }

    guard !hasAccessorKeyword(modifiers: modifiers) else { return node }

    let newModifiers = insertAccessorKeyword(curModifiers: modifiers)
    return node.withModifiers(newModifiers)
  }

  override func visit(_ node: ProtocolDeclSyntax) -> DeclSyntax {
    guard let modifiers = node.modifiers else {
      let formattedProtoDecl = replaceTrivia(on: node,
                                            token: node.protocolKeyword,
                                            leadingTrivia: .spaces(0)) as! ProtocolDeclSyntax
      return formattedProtoDecl.addModifier(modifierKeyword)
    }
    
    guard !hasAccessorKeyword(modifiers: modifiers) else { return node }
    
    let newModifiers = insertAccessorKeyword(curModifiers: modifiers)
    return node.withModifiers(newModifiers)
  }
  
  override func visit(_ node: StructDeclSyntax) -> DeclSyntax {
    guard let modifiers = node.modifiers else {
      //let new = removeFirstTokLeadingTrivia(node: node) as? StructDeclSyntax
      
      let formattedStructDecl = replaceTrivia(on: node,
                                             token: node.structKeyword,
                                             leadingTrivia: .spaces(0)) as! StructDeclSyntax
      return formattedStructDecl.addModifier(modifierKeyword)
    }
    
    guard !hasAccessorKeyword(modifiers: modifiers) else { return node }
    
    let newModifiers = insertAccessorKeyword(curModifiers: modifiers)
    return node.withModifiers(newModifiers)
  }
  
  override func visit(_ node: TypealiasDeclSyntax) -> DeclSyntax {
    guard let modifiers = node.modifiers else {
      let formattedAliasDecl = replaceTrivia(on: node,
                                              token: node.typealiasKeyword,
                                              leadingTrivia: .spaces(0)) as! TypealiasDeclSyntax
      return formattedAliasDecl.addModifier(modifierKeyword)
    }
    
    guard !hasAccessorKeyword(modifiers: modifiers) else { return node }
    
    let newModifiers = insertAccessorKeyword(curModifiers: modifiers)
    return node.withModifiers(newModifiers)
  }
  
  override func visit(_ node: InitializerDeclSyntax) -> DeclSyntax {
    guard let modifiers = node.modifiers else {
      let formattedInitDecl = replaceTrivia(on: node,
                                             token: node.initKeyword,
                                             leadingTrivia: .spaces(0)) as! InitializerDeclSyntax
      return formattedInitDecl.addModifier(modifierKeyword)
    }
    
    guard !hasAccessorKeyword(modifiers: modifiers) else { return node }
    
    let newModifiers = insertAccessorKeyword(curModifiers: modifiers)
    return node.withModifiers(newModifiers)
  }

  // Determines if declaration already has an access keyword in modifiers
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
  
  func insertAccessorKeyword(curModifiers: ModifierListSyntax) -> ModifierListSyntax {
    var newModifiers: [DeclModifierSyntax] = []
    newModifiers.append(contentsOf: curModifiers)
    newModifiers[0] = newModifiers[0].withName(newModifiers[0].name.withoutLeadingTrivia())
    newModifiers.insert(modifierKeyword, at: 0)
    return SyntaxFactory.makeModifierList(newModifiers)
  }

  //func removeFirstTokLeadingTrivia(node: DeclSyntax) -> DeclSyntax {
    //let withoutLead = replaceTrivia(on: node, token: node.firstToken, leadingTrivia: .spaces(0)) as! DeclSyntax
    //return withoutLead
  //}
}

func addModifier(declaration: MemberDeclListItemSyntax,
                 modifierKeyword: DeclModifierSyntax) -> Syntax {
  return AddModifierRewriter(modifierKeyword: modifierKeyword).visit(declaration)
}
