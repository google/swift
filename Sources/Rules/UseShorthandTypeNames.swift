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

/// Shorthand type forms must be used wherever possible.
///
/// Lint: Using a non-shorthand form (e.g. `Array<Element>`) yields a lint error unless the long
///       form is necessary (e.g. `Array<Element>.Index` cannot be shortened.)
///
/// Format: Where possible, shorthand types replace long form types; e.g. `Array<Element>` is
///         converted to `[Element]`.
///
/// - SeeAlso: https://google.github.io/swift#types-with-shorthand-names
public final class UseShorthandTypeNames: SyntaxFormatRule {

  // Visits all potential long forms interpreted as types
  public override func visit(_ node: SimpleTypeIdentifierSyntax) -> TypeSyntax {
    // If nested in a member type identifier, type must be left in long form for the compiler
    guard let parent = node.parent,
          !(parent is MemberTypeIdentifierSyntax) else { return node }
    // Type is in long form if it has a non-nil generic argument clause
    guard let genArg = node.genericArgumentClause else { return node }
    diagnose(.useTypeShorthand(type: node.name.text.lowercased()), on: node)

    // Ensure that all arguments in the clause are shortened and in expected-format by visiting
    // the argument list, first
    let argList = super.visit(genArg.arguments) as! GenericArgumentListSyntax
    // Store trivia of the long form type to pass to the new shorthand type later
    let trivia = retrieveTrivia(from: node)

    switch node.name.text {
    case "Array":
      guard argList.count == 1 else { return node }
      let newArray = shortenArrayType(arguments: argList, trivia: trivia)
      return newArray
    case "Dictionary":
      guard argList.count == 2 else { return node }
      let newDictionary = shortenDictionaryType(arguments: argList, trivia: trivia)
      return newDictionary
    case "Optional":
      guard argList.count == 1 else { return node }
      let newOptional = shortenOptionalType(arguments: argList, trivia: trivia)
      return newOptional
    default:
      break
    }
    return node
  }

  // Visits all potential long forms interpreted as expressions
  public override func visit(_ node: SpecializeExprSyntax) -> ExprSyntax {
    let argList = super.visit(node.genericArgumentClause.arguments) as! GenericArgumentListSyntax
    guard let exp = node.expression as? IdentifierExprSyntax else { return node }
    let trivia = retrieveTrivia(from: node)
    
    switch exp.identifier.text {
    case "Array":
      guard argList.count == 1 else { return node }
      let newArray = shortenArrayExp(arguments: argList, trivia: trivia)
      return newArray ?? node
    case "Dictionary":
      guard argList.count == 2 else { return node }
      let newDictionary = shortenDictExp(arguments: argList, trivia: trivia)
      return newDictionary ?? node
    default:
      break
    }
    return node
  }

  // Get type identifier from generic argument, construct shorthand array form, as a type
  func shortenArrayType(arguments: GenericArgumentListSyntax,
                        trivia: (Trivia, Trivia)) -> TypeSyntax {
    let type = arguments[0].argumentType
    let (leading, trailing) = trivia
    let leftBracket = SyntaxFactory.makeLeftSquareBracketToken(leadingTrivia: leading)
    let rightBracket = SyntaxFactory.makeRightSquareBracketToken(trailingTrivia: trailing)
    let newArray = SyntaxFactory.makeArrayType(leftSquareBracket: leftBracket,
                                               elementType: type,
                                               rightSquareBracket: rightBracket)
    return newArray
  }

  // Get type identifiers from generic arguments, construct shorthand dictionary form, as a type
  func shortenDictionaryType(arguments: GenericArgumentListSyntax,
                         trivia: (Trivia, Trivia)) -> TypeSyntax {
    let firstType = arguments[0].argumentType
    let secondType = arguments[1].argumentType
    let (leading, trailing) = trivia
    let leftBracket = SyntaxFactory.makeLeftSquareBracketToken(leadingTrivia: leading)
    let rightBracket = SyntaxFactory.makeRightSquareBracketToken(trailingTrivia: trailing)
    let colon = SyntaxFactory.makeColonToken(trailingTrivia: .spaces(1))
    let newDictionary = SyntaxFactory.makeDictionaryType(leftSquareBracket: leftBracket,
                                                         keyType: firstType,
                                                         colon: colon,
                                                         valueType: secondType,
                                                         rightSquareBracket: rightBracket)
    return newDictionary
  }

  // Get type identifier from generic argument, construct shorthand optional form, as a type
  func shortenOptionalType(arguments: GenericArgumentListSyntax,
                       trivia: (Trivia, Trivia)) -> TypeSyntax {
    let type = arguments[0].argumentType
    let (_, trailing) = trivia
    let questionMark = SyntaxFactory.makePostfixQuestionMarkToken(trailingTrivia: trailing)
    let newOptional = SyntaxFactory.makeOptionalType(wrappedType: type,
                                                     questionMark: questionMark)
    return newOptional
  }

  // Construct an array expression from type information in the generic argument
  func shortenArrayExp(arguments: GenericArgumentListSyntax,
                       trivia: (Trivia, Trivia)) -> ArrayExprSyntax? {
    var element = SyntaxFactory.makeBlankArrayElement()

    // Get type id, create an expression, nest in the array element
    let arg = arguments[0]
    // Type id can be in a simple type identifier (ex: Int)
    if let simpleId = arg.argumentType as? SimpleTypeIdentifierSyntax {
      let idExp = SyntaxFactory.makeIdentifierExpr(identifier: simpleId.name,
                                                   declNameArguments: nil)
      element = SyntaxFactory.makeArrayElement(expression: idExp, trailingComma: nil)
    // Type id can be in a long form array (ex: Array<Int>.Index)
    } else if let memberTypeId = arg.argumentType as? MemberTypeIdentifierSyntax {
      guard let memberAccessExp = restructureLongForm(member: memberTypeId) else { return nil }
      element = SyntaxFactory.makeArrayElement(expression: memberAccessExp, trailingComma: nil)
    // Type id can be in an array, dictionary, or optional type (ex: [Int], [String: Int], Int?)
    } else if arg.argumentType is ArrayTypeSyntax ||
      arg.argumentType is DictionaryTypeSyntax ||
      arg.argumentType is OptionalTypeSyntax {
      if let newExp = restructureTypeSyntax(type: arg.argumentType) {
        element = SyntaxFactory.makeArrayElement(expression: newExp, trailingComma: nil)
      }
    } else { return nil }

    let elementList = SyntaxFactory.makeArrayElementList([element])
    let (leading, trailing) = trivia
    let leftBracket = SyntaxFactory.makeLeftSquareBracketToken(leadingTrivia: leading)
    let rightBracket = SyntaxFactory.makeRightSquareBracketToken(trailingTrivia: trailing)
    let arrayExp = SyntaxFactory.makeArrayExpr(leftSquare: leftBracket,
                                                 elements: elementList,
                                                 rightSquare: rightBracket)
    return arrayExp
  }

  // Construct a dictionary expression from type information in the generic arguments
  func shortenDictExp(arguments: GenericArgumentListSyntax,
                      trivia: (Trivia, Trivia)) -> DictionaryExprSyntax? {
    let blank = SyntaxFactory.makeBlankIdentifierExpr()
    let colon = SyntaxFactory.makeColonToken(trailingTrivia: .spaces(1))
    var element = SyntaxFactory.makeDictionaryElement(keyExpression: blank,
                                                      colon: colon,
                                                      valueExpression: blank,
                                                      trailingComma: nil)
    // Get type id, create an expression, add to the dictionary element
    for (idx, arg) in arguments.enumerated() {
      if let simpleId = arg.argumentType as? SimpleTypeIdentifierSyntax {
        let idExp = SyntaxFactory.makeIdentifierExpr(identifier: simpleId.name,
                                                     declNameArguments: nil)
        element = idx == 0 ? element.withKeyExpression(idExp) : element.withValueExpression(idExp)
      } else if let memberTypeId = arg.argumentType as? MemberTypeIdentifierSyntax {
        guard let memberAccessExp = restructureLongForm(member: memberTypeId) else { return nil }
        element = idx == 0 ? element.withKeyExpression(memberAccessExp) :
                              element.withValueExpression(memberAccessExp)
      } else if arg.argumentType is ArrayTypeSyntax ||
                arg.argumentType is DictionaryTypeSyntax ||
                arg.argumentType is OptionalTypeSyntax {
        let newExp = restructureTypeSyntax(type: arg.argumentType)
        element = idx == 0 ? element.withKeyExpression(newExp) : element.withValueExpression(newExp)
      } else { return nil }
    }

    let elementList = SyntaxFactory.makeDictionaryElementList([element])
    let (leading, trailing) = trivia
    let leftBracket = SyntaxFactory.makeLeftSquareBracketToken(leadingTrivia: leading)
    let rightBracket = SyntaxFactory.makeRightSquareBracketToken(trailingTrivia: trailing)
    let dictExp = SyntaxFactory.makeDictionaryExpr(leftSquare: leftBracket,
                                                   content: elementList,
                                                   rightSquare: rightBracket)
    return dictExp
  }

  // Convert member type identifier to an equivalent member access expression
  // The node will appear the same, but the structure of the tree is different
  func restructureLongForm(member: MemberTypeIdentifierSyntax) -> MemberAccessExprSyntax? {
    guard let simpleTypeId = member.baseType as? SimpleTypeIdentifierSyntax else { return nil }
    guard let genArgClause = simpleTypeId.genericArgumentClause else { return nil }
    // Node will only change if an argument in the generic argument clause is shortened
    let argClause = super.visit(genArgClause) as! GenericArgumentClauseSyntax
    let idExp = SyntaxFactory.makeIdentifierExpr(identifier: simpleTypeId.name,
                                                 declNameArguments: nil)
    let specialExp = SyntaxFactory.makeSpecializeExpr(expression: idExp,
                                                      genericArgumentClause: argClause)
    let memberAccessExp = SyntaxFactory.makeMemberAccessExpr(base: specialExp,
                                                            dot: member.period,
                                                            name: member.name,
                                                            declNameArguments: nil)
    return memberAccessExp
  }

  // Convert array, dictionary, or optional type to an equivalent expression
  // The node will appear the same, but the structure of the tree is different
  func restructureTypeSyntax(type: TypeSyntax) -> ExprSyntax? {
    if let arrayType = type as? ArrayTypeSyntax {
      let type = arrayType.elementType.description.trimmingCharacters(in: .whitespacesAndNewlines)
      let typeId = SyntaxFactory.makeIdentifier(type)
      let id = SyntaxFactory.makeIdentifierExpr(identifier: typeId,
                                                declNameArguments: nil)
      let element = SyntaxFactory.makeArrayElement(expression: id, trailingComma: nil)
      let elementList = SyntaxFactory.makeArrayElementList([element])
      let arrayExp = SyntaxFactory.makeArrayExpr(leftSquare: arrayType.leftSquareBracket,
                                                 elements: elementList,
                                                 rightSquare: arrayType.rightSquareBracket)
      return arrayExp
    } else if let dictType = type as? DictionaryTypeSyntax {
      let keyType = dictType.keyType.description.trimmingCharacters(in: .whitespacesAndNewlines)
      let keyTypeId = SyntaxFactory.makeIdentifier(keyType)
      let keyIdExp = SyntaxFactory.makeIdentifierExpr(identifier: keyTypeId, declNameArguments: nil)
      let valueType = dictType.valueType.description.trimmingCharacters(in: .whitespacesAndNewlines)
      let valueTypeId = SyntaxFactory.makeIdentifier(valueType)
      let valueIdExp = SyntaxFactory.makeIdentifierExpr(identifier: valueTypeId,
                                                        declNameArguments: nil)
      let element = SyntaxFactory.makeDictionaryElement(keyExpression: keyIdExp,
                                                        colon: dictType.colon,
                                                        valueExpression: valueIdExp,
                                                        trailingComma: nil)
      let elementList = SyntaxFactory.makeDictionaryElementList([element])
      let dictExp = SyntaxFactory.makeDictionaryExpr(leftSquare: dictType.leftSquareBracket,
                                                     content: elementList,
                                                     rightSquare: dictType.rightSquareBracket)
      return dictExp
    } else if let optionalType = type as? OptionalTypeSyntax {
      let type = optionalType.wrappedType.description.trimmingCharacters(
                                                       in: .whitespacesAndNewlines)
      let typeId = SyntaxFactory.makeIdentifier(type)
      let idExp = SyntaxFactory.makeIdentifierExpr(identifier: typeId, declNameArguments: nil)
      let optionalExp = SyntaxFactory.makeOptionalChainingExpr(expression: idExp,
                                                           questionMark: optionalType.questionMark)
      return optionalExp
    }
    return nil
  }

  // Returns trivia from the front and end of the entire given node
  func retrieveTrivia(from node: Syntax) -> (Trivia, Trivia) {
    guard let firstTok = node.firstToken, let lastTok = node.lastToken else { return ([], []) }
    return (firstTok.leadingTrivia, lastTok.trailingTrivia)
  }
}

extension Diagnostic.Message {
  static func useTypeShorthand(type: String) -> Diagnostic.Message {
    return .init(.warning, "use \(type) type shorthand form")
  }
}

