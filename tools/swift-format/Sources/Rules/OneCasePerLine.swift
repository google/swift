import Core
import Foundation
import SwiftSyntax

/// Each enum case with associated values should appear on its own line.
///
/// Lint: If a single `case` declaration declares multiple cases, and any of them have associated
///       values, a lint error is raised.
///
/// Format: All case declarations with associated values will be moved to a new line.
///
/// - SeeAlso: https://google.github.io/swift#enum-cases
public final class OneCasePerLine: SyntaxFormatRule {
  
  public override func visit(_ node: EnumDeclSyntax) -> DeclSyntax {
    let enumMembers = node.members.members
    var newMembers: [MemberDeclListItemSyntax] = []
    var newIndx = 0
    
    for member in enumMembers {
      var numNewMembers = 0
      if let caseMember = member.decl as? EnumCaseDeclSyntax {
        var otherDecl: EnumCaseDeclSyntax = caseMember
        // Add and skip single element case declarations
        guard caseMember.elements.count > 1
          else {
            newMembers.append(SyntaxFactory.makeMemberDeclListItem(decl: caseMember, semicolon: nil))
            newIndx += 1
            continue }
        // Move all cases with associated values to new declarations
        for element in caseMember.elements {
          if element.associatedValue != nil || element.rawValue != nil {
            diagnose(.moveAssociatedOrRawValueCase(name: element.identifier.text), on: element)
            let newRemovedDecl = createAssociateOrRawCaseDecl(fullDecl: caseMember, removedElement: element)
            otherDecl = removeAssociateOrRawCaseDecl(fullDecl: otherDecl)
            let newMember = SyntaxFactory.makeMemberDeclListItem(decl: newRemovedDecl, semicolon: nil)
            newMembers.append(newMember)
            numNewMembers += 1
          }
        }
        // Add case declaration without associated values
        let newMember = SyntaxFactory.makeMemberDeclListItem(decl: otherDecl, semicolon: nil)
        newMembers.insert(newMember, at: newIndx)
      // Add any member that isn't an enum case declaration
      } else { newMembers.append(member)}
      newIndx += numNewMembers + 1
    }
    
    return node.withMembers(SyntaxFactory.makeMemberDeclBlock(leftBrace: SyntaxFactory.makeLeftBraceToken(),
                                                              members: SyntaxFactory.makeMemberDeclList(newMembers),
                                                              rightBrace: SyntaxFactory.makeRightBraceToken().withOneLeadingNewline()))
  }
  
  func createAssociateOrRawCaseDecl(fullDecl: EnumCaseDeclSyntax, removedElement: EnumCaseElementSyntax) -> EnumCaseDeclSyntax {
    let formattedElement = removedElement.withTrailingComma(nil)
    let newDecl = SyntaxFactory.makeEnumCaseDecl(attributes: fullDecl.attributes, modifiers: fullDecl.modifiers, caseKeyword: fullDecl.caseKeyword, elements: SyntaxFactory.makeEnumCaseElementList([formattedElement]))
    return newDecl
  }
  
  // Returns formatted declaration of cases without associated values
  func removeAssociateOrRawCaseDecl(fullDecl: EnumCaseDeclSyntax) -> EnumCaseDeclSyntax {
    var newList: [EnumCaseElementSyntax] = []
    for element in fullDecl.elements {
      if element.associatedValue == nil && element.rawValue == nil { newList.append(element) }
    }
    
    let (last, indx) = (newList[newList.count - 1], newList.count - 1)
    if last.trailingComma != nil {
      newList[indx] = last.withTrailingComma(nil)
    }
    return fullDecl.withElements(SyntaxFactory.makeEnumCaseElementList(newList))
  }
}

extension Diagnostic.Message {
  static func moveAssociatedOrRawValueCase(name: String) -> Diagnostic.Message {
    return .init(.warning, "Move \(name) case to a new line")
  }
}
