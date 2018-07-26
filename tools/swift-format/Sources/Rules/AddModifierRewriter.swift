import Core
import Foundation
import SwiftSyntax

private final class AddModifierRewriter: SyntaxRewriter {
  let modifierKeyword: DeclModifierSyntax

  init(modifierKeyword: DeclModifierSyntax) {
    self.modifierKeyword = modifierKeyword
  }


  override func visit(_ node: VariableDeclSyntax) -> DeclSyntax {
    // Check for modifiers, if none, put accessor keyword before the first token
    guard let modifiers = node.modifiers else {
      guard let newDecl = removeFirstTokLeadingTrivia(node: node)
        as? VariableDeclSyntax else { return node }
      return newDecl.addModifier(modifierKeyword)
    }
    // If variable already has an accessor keyword, skip (do not overwrite)
    guard !hasAccessorKeyword(modifiers: modifiers) else { return node }

    // Put accessor keyword before the first modifier keyword in the declaration
    let newModifiers = insertAccessorKeyword(curModifiers: modifiers)
    return node.withModifiers(newModifiers)
  }

  override func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
    guard let modifiers = node.modifiers else {
      guard let newDecl = removeFirstTokLeadingTrivia(node: node)
        as? FunctionDeclSyntax else { return node }
      return newDecl.addModifier(modifierKeyword)
    }
    guard !hasAccessorKeyword(modifiers: modifiers) else { return node }
    let newModifiers = insertAccessorKeyword(curModifiers: modifiers)
    return node.withModifiers(newModifiers)
  }

  override func visit(_ node: AssociatedtypeDeclSyntax) -> DeclSyntax {
    guard let modifiers = node.modifiers else {
      guard let newDecl = removeFirstTokLeadingTrivia(node: node)
        as? AssociatedtypeDeclSyntax else { return node }
      return newDecl.addModifier(modifierKeyword)
    }
    guard !hasAccessorKeyword(modifiers: modifiers) else { return node }
    let newModifiers = insertAccessorKeyword(curModifiers: modifiers)
    return node.withModifiers(newModifiers)
  }

  override func visit(_ node: ClassDeclSyntax) -> DeclSyntax {
    guard let modifiers = node.modifiers else {
      guard let newDecl = removeFirstTokLeadingTrivia(node: node)
        as? ClassDeclSyntax else { return node }
      return newDecl.addModifier(modifierKeyword)
    }
    guard !hasAccessorKeyword(modifiers: modifiers) else { return node }
    let newModifiers = insertAccessorKeyword(curModifiers: modifiers)
    return node.withModifiers(newModifiers)
  }

  override func visit(_ node: EnumDeclSyntax) -> DeclSyntax {
    guard let modifiers = node.modifiers else {
      guard let newDecl = removeFirstTokLeadingTrivia(node: node)
        as? EnumDeclSyntax else { return node }
      return newDecl.addModifier(modifierKeyword)
    }
    guard !hasAccessorKeyword(modifiers: modifiers) else { return node }
    let newModifiers = insertAccessorKeyword(curModifiers: modifiers)
    return node.withModifiers(newModifiers)
  }

  override func visit(_ node: ProtocolDeclSyntax) -> DeclSyntax {
    guard let modifiers = node.modifiers else {
      guard let newDecl = removeFirstTokLeadingTrivia(node: node)
        as? ProtocolDeclSyntax else { return node }
      return newDecl.addModifier(modifierKeyword)
    }
    guard !hasAccessorKeyword(modifiers: modifiers) else { return node }
    let newModifiers = insertAccessorKeyword(curModifiers: modifiers)
    return node.withModifiers(newModifiers)
  }
  
  override func visit(_ node: StructDeclSyntax) -> DeclSyntax {
    guard let modifiers = node.modifiers else {
      guard let newDecl = removeFirstTokLeadingTrivia(node: node)
        as? StructDeclSyntax else { return node }
      return newDecl.addModifier(modifierKeyword)
    }
    guard !hasAccessorKeyword(modifiers: modifiers) else { return node }
    let newModifiers = insertAccessorKeyword(curModifiers: modifiers)
    return node.withModifiers(newModifiers)
  }
  
  override func visit(_ node: TypealiasDeclSyntax) -> DeclSyntax {
    guard let modifiers = node.modifiers else {
      guard let newDecl = removeFirstTokLeadingTrivia(node: node)
        as? TypealiasDeclSyntax else { return node }
      return newDecl.addModifier(modifierKeyword)
    }
    guard !hasAccessorKeyword(modifiers: modifiers) else { return node }
    let newModifiers = insertAccessorKeyword(curModifiers: modifiers)
    return node.withModifiers(newModifiers)
  }

  override func visit(_ node: InitializerDeclSyntax) -> DeclSyntax {
    guard let modifiers = node.modifiers else {
      guard let newDecl = removeFirstTokLeadingTrivia(node: node)
        as? InitializerDeclSyntax else { return node }
      return newDecl.addModifier(modifierKeyword)
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

  // Puts the access keyword at the beginning of the given modifier list
  func insertAccessorKeyword(curModifiers: ModifierListSyntax) -> ModifierListSyntax {
    var newModifiers: [DeclModifierSyntax] = []
    newModifiers.append(contentsOf: curModifiers)
    newModifiers[0] = newModifiers[0].withName(newModifiers[0].name.withoutLeadingTrivia())
    newModifiers.insert(modifierKeyword, at: 0)
    return SyntaxFactory.makeModifierList(newModifiers)
  }

  func removeFirstTokLeadingTrivia(node: DeclSyntax) -> DeclSyntax {
    let withoutLeadTrivia = replaceTrivia(on: node,
                                          token: node.firstToken,
                                          leadingTrivia: []) as! DeclSyntax
    return withoutLeadTrivia
  }
}

func addModifier(declaration: MemberDeclListItemSyntax,
                 modifierKeyword: DeclModifierSyntax) -> Syntax {
  return AddModifierRewriter(modifierKeyword: modifierKeyword).visit(declaration)
}
