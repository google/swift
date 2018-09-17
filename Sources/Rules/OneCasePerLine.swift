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
    var newMembers: [DeclSyntax] = []
    var newIndx = 0
    
    for member in enumMembers {
      var numNewMembers = 0
      if let caseMember = member as? EnumCaseDeclSyntax {
        var otherDecl: EnumCaseDeclSyntax? = caseMember
        // Add and skip single element case declarations
        guard caseMember.elements.count > 1 else {
            newMembers.append(caseMember)
            newIndx += 1
            continue
        }
        // Move all cases with associated/raw values to new declarations
        for element in caseMember.elements {
          if element.associatedValue != nil || element.rawValue != nil {
            diagnose(.moveAssociatedOrRawValueCase(name: element.identifier.text), on: element)
            let newRemovedDecl = createAssociateOrRawCaseDecl(fullDecl: caseMember,
                                                              removedElement: element)
            otherDecl = removeAssociateOrRawCaseDecl(fullDecl: otherDecl)
            newMembers.append(newRemovedDecl)
            numNewMembers += 1
          }
        }
        // Add case declaration of remaining elements without associated/raw values, if any
        if let otherDecl = otherDecl {
          newMembers.insert(otherDecl, at: newIndx)
          newIndx += 1
        }
      // Add any member that isn't an enum case declaration
      } else {
        newMembers.append(member)
        newIndx += 1
      }
      newIndx += numNewMembers
    }

    let newMemberBlock = SyntaxFactory.makeMemberDeclBlock(
      leftBrace: node.members.leftBrace,
      members: SyntaxFactory.makeDeclList(newMembers),
      rightBrace: node.members.rightBrace)
    return node.withMembers(newMemberBlock)
  }
  
  func createAssociateOrRawCaseDecl(fullDecl: EnumCaseDeclSyntax,
                                    removedElement: EnumCaseElementSyntax) -> EnumCaseDeclSyntax {
    let formattedElement = removedElement.withTrailingComma(nil)
    let newElementList = SyntaxFactory.makeEnumCaseElementList([formattedElement])
    let newDecl = SyntaxFactory.makeEnumCaseDecl(attributes: fullDecl.attributes,
                                                 modifiers: fullDecl.modifiers,
                                                 caseKeyword: fullDecl.caseKeyword,
                                                 elements: newElementList)
    return newDecl
  }

  // Returns formatted declaration of cases without associated/raw values, or nil if all cases had
  // a raw or associate value
  func removeAssociateOrRawCaseDecl(fullDecl: EnumCaseDeclSyntax?) -> EnumCaseDeclSyntax? {
    guard let fullDecl = fullDecl else { return nil }
    var newList: [EnumCaseElementSyntax] = []

    for element in fullDecl.elements {
      if element.associatedValue == nil && element.rawValue == nil { newList.append(element) }
    }

    guard newList.count > 0 else { return nil }
    let (last, indx) = (newList[newList.count - 1], newList.count - 1)
    if last.trailingComma != nil {
      newList[indx] = last.withTrailingComma(nil)
    }
    return fullDecl.withElements(SyntaxFactory.makeEnumCaseElementList(newList))
  }
}

extension Diagnostic.Message {
  static func moveAssociatedOrRawValueCase(name: String) -> Diagnostic.Message {
    return .init(.warning, "move \(name) case to a new line")
  }
}
