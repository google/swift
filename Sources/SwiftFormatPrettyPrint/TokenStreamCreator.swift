//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2018 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import SwiftFormatConfiguration
import SwiftFormatCore
import SwiftSyntax

private let rangeOperators: Set = ["...", "..<"]

private final class TokenStreamCreator: SyntaxVisitor {
  private var tokens = [Token]()
  private var beforeMap = [TokenSyntax: [Token]]()
  private var afterMap = [TokenSyntax: [[Token]]]()
  private let config: Configuration

  init(configuration: Configuration) {
    self.config = configuration
  }

  func makeStream(from node: Syntax) -> [Token] {
    visit(node)
    defer { tokens = [] }
    return tokens
  }

  var openings = 0

  func before(_ token: TokenSyntax?, tokens: Token...) {
    guard let tok = token else { return }
    for preToken in tokens {
      if case .open = preToken {
        openings += 1
      } else if case .close = preToken {
        assert(openings > 0)
        openings -= 1
      }
    }
    beforeMap[tok, default: []] += tokens
  }

  func after(_ token: TokenSyntax?, tokens: Token...) {
    guard let tok = token else { return }
    for postToken in tokens {
      if case .open = postToken {
        openings += 1
      } else if case .close = postToken {
        assert(openings > 0)
        openings -= 1
      }
    }
    afterMap[tok, default: []].append(tokens)
  }

  private func insertToken<Node: Collection>(
    _ token: Token,
    betweenChildrenOf collectionNode: Node
  ) where Node.Element: Syntax, Node.Index == Int {
    if collectionNode.count > 0 {
      for i in 0..<(collectionNode.count - 1) {
        after(collectionNode[i].lastToken, tokens: token)
      }
    }
  }

  override func visitPre(_ node: Syntax) {}

  override func visit(_ node: DeclNameArgumentsSyntax) {
    super.visit(node)
  }

  override func visit(_ node: BinaryOperatorExprSyntax) {
    before(node.operatorToken, tokens: .break)
    after(node.operatorToken, tokens: .break)
    super.visit(node)
  }

  override func visit(_ node: TupleExprSyntax) {
    after(
      node.leftParen,
      tokens: .break(size: 0, offset: 2), .open(.consistent, 0), .break(size: 0),
        .open(.consistent, 0)
    )
    before(node.rightParen, tokens: .close, .break(size: 0, offset: -2), .close)
    super.visit(node)
  }

  override func visit(_ node: TupleElementListSyntax) {
    insertToken(.break, betweenChildrenOf: node)
    super.visit(node)
  }

  override func visit(_ node: TupleElementSyntax) {
    before(node.firstToken, tokens: .open)
    after(node.lastToken, tokens: .close)
    super.visit(node)
  }

  override func visit(_ node: ArrayExprSyntax) {
    after(
      node.leftSquare,
      tokens: .break(size: 0, offset: 2), .open(.consistent, 0), .break(size: 0),
        .open(.consistent, 0)
    )
    before(node.rightSquare, tokens: .close, .break(size: 0, offset: -2), .close)
    super.visit(node)
  }

  override func visit(_ node: ArrayElementListSyntax) {
    insertToken(.break, betweenChildrenOf: node)
    super.visit(node)
  }

  override func visit(_ node: ArrayElementSyntax) {
    before(node.firstToken, tokens: .open)
    after(node.lastToken, tokens: .close)
    super.visit(node)
  }

  override func visit(_ node: DictionaryExprSyntax) {
    after(
      node.leftSquare,
      tokens: .break(size: 0, offset: 2), .open(.consistent, 0), .break(size: 0),
      .open(.consistent, 0)
    )
    before(node.rightSquare, tokens: .close, .break(size: 0, offset: -2), .close)
    super.visit(node)
  }

  override func visit(_ node: DictionaryElementListSyntax) {
    insertToken(.break, betweenChildrenOf: node)
    super.visit(node)
  }

  override func visit(_ node: DictionaryTypeSyntax) {
    after(node.colon, tokens: .space)
    super.visit(node)
  }

  override func visit(_ node: DictionaryElementSyntax) {
    before(node.firstToken, tokens: .open)
    after(node.colon, tokens: .break(offset: 2))
    after(node.lastToken, tokens: .close)
    super.visit(node)
  }

  override func visit(_ node: ImplicitMemberExprSyntax) {
    super.visit(node)
  }

  override func visit(_ node: FunctionParameterSyntax) {
    before(node.firstToken, tokens: .open)
    after(node.colon, tokens: .break)
    before(node.secondName, tokens: .break)

    if let trailingComma = node.trailingCommaWorkaround {
      after(trailingComma, tokens: .close, .break)
    } else {
      after(node.lastToken, tokens: .close)
    }
    super.visit(node)
  }

  override func visit(_ node: MemberAccessExprSyntax) {
    super.visit(node)
  }

  override func visit(_ node: FunctionCallExprSyntax) {
    if node.argumentList.count == 1, node.argumentList[0].expression is ClosureExprSyntax {
      super.visit(node)
      return
    }
    if node.argumentList.count > 0 {
      after(node.leftParen, tokens: .break(size: 0, offset: 2), .open(.consistent, 0))
      before(node.rightParen, tokens: .break(size: 0, offset: -2), .close)
    }
    before(node.trailingClosure?.leftBrace, tokens: .space)
    super.visit(node)
  }

  override func visit(_ node: FunctionCallArgumentSyntax) {
    after(node.colon, tokens: .break)

      before(node.firstToken, tokens: .open)
      if let trailingComma = node.trailingComma {
        after(trailingComma, tokens: .close, .break)
      } else {
        after(node.lastToken, tokens: .close)
      }
      super.visit(node)
  }

  override func visit(_ node: ClosureExprSyntax) {
    before(node.firstToken, tokens: .reset)
    if let signature = node.signature {
      before(signature.firstToken, tokens: .break(offset: 2))
      before(node.statements.firstToken, tokens: .newline(offset: 2), .open(.consistent, 0))
      before(node.rightBrace, tokens: .break(offset: -2), .close)
    } else {
      before(node.statements.firstToken, tokens: .break(offset: 2), .open(.consistent, 0))
      before(node.rightBrace, tokens: .break(offset: -2), .close)
    }

    super.visit(node)
  }

  override func visit(_ node: ClosureParamSyntax) {
    after(node.trailingComma, tokens: .break)
    super.visit(node)
  }

  override func visit(_ node: ClosureSignatureSyntax) {
    before(node.firstToken, tokens: .open(.inconsistent, 2))
    after(node.input?.lastToken, tokens: .break)
    after(node.output?.lastToken, tokens: .break)
    after(node.throwsTok, tokens: .break)
    after(node.lastToken, tokens: .close)
    super.visit(node)
  }

  override func visit(_ node: ClosureCaptureSignatureSyntax) {
    super.visit(node)
  }

  override func visit(_ node: ClosureCaptureItemSyntax) {
    super.visit(node)
  }

  override func visit(_ node: SubscriptExprSyntax) {
    super.visit(node)
  }

  override func visit(_ node: ExpressionSegmentSyntax) {
    super.visit(node)
  }

  override func visit(_ node: ObjcKeyPathExprSyntax) {
    super.visit(node)
  }

  override func visit(_ node: AssignmentExprSyntax) {
    before(node.assignToken, tokens: .break)
    after(node.assignToken, tokens: .break)
    super.visit(node)
  }

  override func visit(_ node: ObjectLiteralExprSyntax) {
    super.visit(node)
  }

  override func visit(_ node: ParameterClauseSyntax) {
    after(node.leftParen, tokens: .break(size: 0, offset: 2), .open(.consistent, 0))
    before(node.rightParen, tokens: .break(size: 0, offset: -2), .close)
    super.visit(node)
  }

  override func visit(_ node: ReturnClauseSyntax) {
    before(node.firstToken, tokens: .open)
    before(node.returnType.firstToken, tokens: .break)
    after(node.lastToken, tokens: .close)
    super.visit(node)
  }

  override func visit(_ node: IfConfigDeclSyntax) {
    super.visit(node)
  }

  override func visit(_ node: IfConfigClauseSyntax) {
    after(node.poundKeyword, tokens: .break)
    after(node.condition?.lastToken, tokens: .newline)
    super.visit(node)
  }

  override func visit(_ node: MemberDeclBlockSyntax) {
    for i in 0..<(node.members.count - 1) {
      after(node.members[i].lastToken, tokens: .newline)
    }
    super.visit(node)
  }

  override func visit(_ node: SourceFileSyntax) {
    super.visit(node)
  }

  override func visit(_ node: EnumDeclSyntax) {
    if let attributes = node.attributes {
      before(node.firstToken, tokens: .space(size: 0), .open(.consistent, 0))
      after(attributes.lastToken, tokens: .open)
    } else {
      before(node.firstToken, tokens: .space(size: 0), .open(.consistent, 0), .open)
    }

    after(node.enumKeyword, tokens: .break)

    before(
      node.genericWhereClause?.firstToken,
      tokens: .break, .open(.inconsistent, 0), .break(size: 0), .open(.consistent, 0)
    )
    after(node.genericWhereClause?.lastToken, tokens: .break, .close, .close)

    if node.genericWhereClause == nil {
      before(node.members.leftBrace, tokens: .break)
    }
    after(
      node.members.leftBrace,
      tokens: .close, .close, .break(size: 0, offset: 2), .open(.consistent, 0)
    )
    before(node.members.rightBrace, tokens: .break(size: 0, offset: -2), .close)

    super.visit(node)
  }

  override func visit(_ node: EnumCaseDeclSyntax) {
    before(node.firstToken, tokens: .open)
    after(node.caseKeyword, tokens: .break)
    after(node.lastToken, tokens: .close)
    super.visit(node)
  }

  override func visit(_ node: OperatorDeclSyntax) {
    super.visit(node)
  }

  override func visit(_ node: EnumCaseElementSyntax) {
    after(node.trailingComma, tokens: .break(offset: 2))
    super.visit(node)
  }

  override func visit(_ node: ObjcSelectorExprSyntax) {
    super.visit(node)
  }

  override func visit(_ node: InfixOperatorGroupSyntax) {
    super.visit(node)
  }

  override func visit(_ node: PrecedenceGroupDeclSyntax) {
    super.visit(node)
  }

  override func visit(_ node: PrecedenceGroupRelationSyntax) {
    super.visit(node)
  }

  override func visit(_ node: PrecedenceGroupAssignmentSyntax) {
    super.visit(node)
  }

  override func visit(_ node: PrecedenceGroupNameElementSyntax) {
    super.visit(node)
  }

  override func visit(_ node: PrecedenceGroupAssociativitySyntax) {
    super.visit(node)
  }

  override func visit(_ node: AccessLevelModifierSyntax) {
    super.visit(node)
  }

  override func visit(_ node: AccessorParameterSyntax) {
    super.visit(node)
  }

  override func visit(_ node: AccessorDeclSyntax) {
    before(node.firstToken, tokens: .space(size: 0), .open(.consistent, 0))
    if let body = node.body {
      before(node.accessorKind, tokens: .open, .open)
      before(body.leftBrace, tokens: .break)
      after(body.leftBrace, tokens: .close, .break(offset: 2), .open(.consistent, 0))
      before(body.rightBrace, tokens: .break(offset: -2), .close, .close)
    }
    after(node.lastToken, tokens: .close)
    super.visit(node)
  }

  override func visit(_ node: AccessorBlockSyntax) {
    if !(node.parent is SubscriptDeclSyntax) {
      after(node.leftBrace, tokens: .break(offset: 2), .open(.consistent, 0))
      before(node.rightBrace, tokens: .break(offset: -2), .close)
    }
    super.visit(node)
  }

  override func visit(_ node: AccessorListSyntax) {
    if node.count > 1 {
      after(node.first?.lastToken, tokens: .break)
    }
    super.visit(node)
  }

  override func visit(_ node: CodeBlockSyntax) {
    insertToken(.newline, betweenChildrenOf: node.statements)
    super.visit(node)
  }

  override func visit(_ node: CodeBlockItemListSyntax) {
    if node.parent is AccessorBlockSyntax || node.parent is ClosureExprSyntax, node.count > 0 {
      insertToken(.newline, betweenChildrenOf: node)
    }
    super.visit(node)
  }

  override func visit(_ node: CodeBlockItemSyntax) {
    before(node.firstToken, tokens: .open)
    if !(node.parent?.parent is CodeBlockSyntax ||
           node.parent?.parent is SwitchCaseSyntax ||
           node.parent?.parent is ClosureExprSyntax ||
           node.parent?.parent is AccessorBlockSyntax
         ) {
      after(node.lastToken, tokens: .close, .newline)
    } else {
      after(node.lastToken, tokens: .close)
    }
    super.visit(node)
  }

  override func visit(_ node: SwitchStmtSyntax) {
    before(node.switchKeyword, tokens: .open(.inconsistent, 7))
    after(node.switchKeyword, tokens: .space)
    after(node.expression.lastToken, tokens: .close, .break)
    after(node.leftBrace, tokens: .newline, .open(.consistent, 0))
    before(node.rightBrace, tokens: .break, .close)
    super.visit(node)
  }

  override func visit(_ node: SwitchCaseSyntax) {
    before(node.firstToken, tokens: .open)
    after(node.label.lastToken, tokens: .newline(offset: 2), .open(.consistent, 0))
    insertToken(.newline, betweenChildrenOf: node.statements)
    after(node.lastToken, tokens: .break(offset: -2), .close, .close)
    super.visit(node)
  }

  override func visit(_ node: SwitchCaseLabelSyntax) {
    before(node.caseKeyword, tokens: .open(.inconsistent, 5))
    after(node.caseKeyword, tokens: .space)
    after(node.colon, tokens: .close)
    super.visit(node)
  }

  override func visit(_ node: CaseItemSyntax) {
    before(node.firstToken, tokens: .open)
    before(node.whereClause?.firstToken, tokens: .break)
    if let trailingComma = node.trailingComma {
      after(trailingComma, tokens: .close, .break)
    } else {
      after(node.lastToken, tokens: .close)
    }
    super.visit(node)
  }

  override func visit(_ node: SwitchDefaultLabelSyntax) {
    // Implementation not needed.
    super.visit(node)
  }

  override func visit(_ node: GenericParameterClauseSyntax) {
    after(node.leftAngleBracket, tokens: .break(size: 0, offset: 2), .open(.consistent, 0))
    before(node.rightAngleBracket, tokens: .break(size: 0, offset: -2), .close)
    super.visit(node)
  }

  override func visit(_ node: ArrayTypeSyntax) {
    super.visit(node)
  }

  override func visit(_ node: TupleTypeSyntax) {
    after(node.leftParen, tokens: .open(.consistent, 2), .break(size: 0))
    before(node.rightParen, tokens: .break(size: 0), .close)
    super.visit(node)
  }

  override func visit(_ node: FunctionTypeSyntax) {
    after(node.leftParen, tokens: .break(size: 0, offset: 2), .open(.consistent, 0))
    before(node.rightParen, tokens: .break(size: 0, offset: -2), .close)
    before(node.arrow, tokens: .break)
    before(node.returnType.firstToken, tokens: .break)
    super.visit(node)
  }

  override func visit(_ node: GenericArgumentClauseSyntax) {
    after(node.leftAngleBracket, tokens: .break(size: 0, offset: 2), .open(.consistent, 0))
    before(node.rightAngleBracket, tokens: .break(size: 0, offset: -2), .close)
    super.visit(node)
  }

  override func visit(_ node: TuplePatternSyntax) {
    after(node.leftParen, tokens: .open(.consistent, 2), .break(size: 0))
    before(node.rightParen, tokens: .break(size: 0), .close)
    super.visit(node)
  }

  override func visit(_ node: AsExprSyntax) {
    before(node.asTok, tokens: .space)
    before(node.typeName.firstToken, tokens: .break)
    super.visit(node)
  }

  override func visit(_ node: DoStmtSyntax) {
    after(node.doKeyword, tokens: .space)
    after(node.body.leftBrace, tokens: .newline(offset: 2), .open(.consistent, 0))
    before(node.body.rightBrace, tokens: .break(offset: -2), .close)
    super.visit(node)
  }

  override func visit(_ node: CatchClauseSyntax) {
    before(node.catchKeyword, tokens: .space)
    before(node.pattern?.firstToken, tokens: .break)

    if let whereClause = node.whereClause {
      before(whereClause.firstToken, tokens: .break(offset: 2), .open(.consistent, 0))
      before(node.body.leftBrace, tokens: .break(offset: -2), .close)
    } else {
      before(node.body.leftBrace, tokens: .break)
    }

    after(node.body.leftBrace, tokens: .newline(offset: 2), .open(.consistent, 0))
    before(node.body.rightBrace, tokens: .break(offset: -2), .close)
    super.visit(node)
  }

  override func visit(_ node: IfStmtSyntax) {
    before(node.ifKeyword, tokens: .open(.inconsistent, 3))
    after(node.ifKeyword, tokens: .space)
    before(node.body.leftBrace, tokens: .break(offset: -3), .close)

    after(node.body.leftBrace, tokens: .newline(offset: 2), .open(.consistent, 0))
    before(node.body.rightBrace, tokens: .newline(offset: -2), .close)

    before(node.elseKeyword, tokens: .break)
    after(node.elseKeyword, tokens: .break)

    if let elseBody = node.elseBody as? CodeBlockSyntax {
      after(elseBody.leftBrace, tokens: .newline(offset: 2), .open(.consistent, 0))
      before(elseBody.rightBrace, tokens: .newline(offset: -2), .close)
    }
    super.visit(node)
  }

  override func visit(_ node: IsExprSyntax) {
    before(node.isTok, tokens: .space)
    after(node.isTok, tokens: .break)
    super.visit(node)
  }

  override func visit(_ node: TryExprSyntax) {
    before(node.expression.firstToken, tokens: .break)
    super.visit(node)
  }

  override func visit(_ node: TypeExprSyntax) {
    super.visit(node)
  }

  override func visit(_ node: ArrowExprSyntax) {
    before(node.throwsToken, tokens: .break)
    before(node.arrowToken, tokens: .break)
    after(node.arrowToken, tokens: .break)
    super.visit(node)
  }

  override func visit(_ node: AttributeSyntax) {
    if node.balancedTokens.count > 0 {
      for i in 0..<(node.balancedTokens.count - 1) {
        let tokens = node.balancedTokens
        switch (tokens[i].tokenKind, tokens[i+1].tokenKind) {
        case (.leftParen, _): ()
        case (_, .rightParen): ()
        case (_, .comma): ()
        case (_, .colon): ()
        default:
          after(tokens[i], tokens: .space)
        }
      }
      after(node.balancedTokens.lastToken, tokens: .newline)
    } else {
      if node.parent?.parent is ImportDeclSyntax {
        after(node.lastToken, tokens: .space)
      } else {
        after(node.lastToken, tokens: .break)
      }
    }
    super.visit(node)
  }

  override func visit(_ node: BreakStmtSyntax) {
    before(node.label, tokens: .break(offset: 2))
    super.visit(node)
  }

  override func visit(_ node: ClassDeclSyntax) {
    if let attributes = node.attributes {
      before(node.firstToken, tokens: .space(size: 0), .open(.consistent, 0))
      after(attributes.lastToken, tokens: .open)
    } else {
      before(node.firstToken, tokens: .space(size: 0), .open(.consistent, 0), .open)
    }

    after(node.classKeyword, tokens: .break)

    before(
      node.genericWhereClause?.firstToken,
      tokens: .break, .open(.inconsistent, 0), .break(size: 0), .open(.consistent, 0)
    )
    after(node.genericWhereClause?.lastToken, tokens: .break, .close, .close)

    if node.genericWhereClause == nil {
      before(node.members.leftBrace, tokens: .break)
    }
    after(
      node.members.leftBrace,
      tokens: .close, .close, .break(size: 0, offset: 2), .open(.consistent, 0)
    )
    before(node.members.rightBrace, tokens: .break(size: 0, offset: -2), .close)

    super.visit(node)
  }

  override func visit(_ node: DeferStmtSyntax) {
    after(node.deferKeyword, tokens: .break)
    after(node.body.leftBrace, tokens: .break(offset: 2), .open(.consistent, 0))
    before(node.body.rightBrace, tokens: .break(offset: -2), .close)
    super.visit(node)
  }

  override func visit(_ node: ElseBlockSyntax) {
    super.visit(node)
  }

  override func visit(_ node: ForInStmtSyntax) {
    before(node.forKeyword, tokens: .open(.inconsistent, 4))
    after(node.forKeyword, tokens: .space)
    before(node.inKeyword, tokens: .break)
    after(node.inKeyword, tokens: .space)

    if let whereClause = node.whereClause {
      before(
        whereClause.firstToken,
        tokens: .close, .break, .open(.inconsistent, 0), .break(size: 0), .open(.consistent, 0)
      )
      before(node.body.leftBrace, tokens: .break, .close, .close)
    } else {
      before(node.body.leftBrace, tokens: .close, .break)
    }

    after(node.body.leftBrace, tokens: .newline(offset: 2), .open(.consistent, 0))
    before(node.body.rightBrace, tokens: .newline(offset: -2), .close)

    super.visit(node)
  }

  override func visit(_ node: GuardStmtSyntax) {
    before(node.guardKeyword, tokens: .open(.inconsistent, 6))
    after(node.guardKeyword, tokens: .break)
    before(node.elseKeyword, tokens: .close, .break)
    after(node.elseKeyword, tokens: .break)

    after(node.body.leftBrace, tokens: .break(offset: 2), .open(.consistent, 0))
    before(node.body.rightBrace, tokens: .break(offset: -2), .close)
    super.visit(node)
  }

  override func visit(_ node: ConditionElementSyntax) {
    after(node.trailingComma, tokens:. break)
    super.visit(node)
  }

  override func visit(_ node: InOutExprSyntax) {
    super.visit(node)
  }

  override func visit(_ node: ThrowStmtSyntax) {
    super.visit(node)
  }

  override func visit(_ node: WhileStmtSyntax) {
    before(node.firstToken, tokens: .open(.inconsistent, 6))
    after(node.labelColon, tokens: .space)
    after(node.whileKeyword, tokens: .space)
    before(node.body.leftBrace, tokens: .break(offset: -6), .close)
    after(node.body.leftBrace, tokens: .break(offset: 2), .open(.consistent, 0))
    before(node.body.rightBrace, tokens: .break(offset: -2), .close)
    super.visit(node)
  }

  override func visit(_ node: ImportDeclSyntax) {
    after(node.importTok, tokens: .space)
    after(node.importKind, tokens: .space)
    super.visit(node)
  }

  override func visit(_ node: ReturnStmtSyntax) {
    before(node.firstToken, tokens: .open)
    before(node.expression?.firstToken, tokens: .break(offset: 2))
    after(node.lastToken, tokens: .close)
    super.visit(node)
  }

  override func visit(_ node: StructDeclSyntax) {
    if let attributes = node.attributes {
      before(node.firstToken, tokens: .space(size: 0), .open(.consistent, 0))
      after(attributes.lastToken, tokens: .open)
    } else {
      before(node.firstToken, tokens: .space(size: 0), .open(.consistent, 0), .open)
    }

    after(node.structKeyword, tokens: .break)

    before(
      node.genericWhereClause?.firstToken,
      tokens: .break, .open(.inconsistent, 0), .break(size: 0), .open(.consistent, 0)
    )
    after(node.genericWhereClause?.lastToken, tokens: .break, .close, .close)


    if node.genericWhereClause == nil {
      before(node.members.leftBrace, tokens: .break)
    }
    after(
      node.members.leftBrace,
      tokens: .close, .close, .break(size: 0, offset: 2), .open(.consistent, 0)
    )
    before(node.members.rightBrace, tokens: .break(size: 0, offset: -2), .close)

    super.visit(node)
  }

  override func visit(_ node: DotSelfExprSyntax) {
    super.visit(node)
  }

  override func visit(_ node: KeyPathExprSyntax) {
    super.visit(node)
  }

  override func visit(_ node: TernaryExprSyntax) {
    before(node.conditionExpression.firstToken, tokens: .open(.inconsistent, 2))
    before(node.questionMark, tokens: .break)
    after(node.questionMark, tokens: .space)
    before(node.colonMark, tokens: .break)
    after(node.colonMark, tokens: .space)
    after(node.secondChoice.lastToken, tokens: .close)
    super.visit(node)
  }

  override func visit(_ node: WhereClauseSyntax) {
    before(node.whereKeyword, tokens: .open(.inconsistent, 2))
    after(node.whereKeyword, tokens: .space)
    after(node.lastToken, tokens: .close)
    super.visit(node)
  }

  override func visit(_ node: ContinueStmtSyntax) {
    super.visit(node)
  }

  override func visit(_ node: DeclModifierSyntax) {
    after(node.name, tokens: .break)
    super.visit(node)
  }

  override func visit(_ node: FunctionDeclSyntax) {
    before(node.firstToken, tokens: .open(.inconsistent, 0))

    if let attributes = node.attributes {
      before(node.firstToken, tokens: .space(size: 0), .open(.consistent, 0))
      after(attributes.lastToken, tokens: .open)
    } else {
      before(node.firstToken, tokens: .space(size: 0), .open(.consistent, 0), .open)
    }

    after(node.funcKeyword, tokens: .break)

    before(
      node.genericWhereClause?.firstToken,
      tokens: .break, .open(.inconsistent, 0), .break(size: 0), .open(.consistent, 0)
    )
    after(node.genericWhereClause?.lastToken, tokens: .break, .close, .close)

    if let body = node.body {
      if node.genericWhereClause == nil {
        before(body.leftBrace, tokens: .break)
      }
      after(body.leftBrace, tokens: .close, .close, .break(offset: 2), .open(.consistent, 0))
      before(body.rightBrace, tokens: .break(offset: -2), .close)
    } else {
      // FunctionDecls in protocols won't have bodies, so make sure we close the correct number of
      // groups in that case as well.
      after(node.lastToken, tokens: .close, .close)
    }

    after(node.lastToken, tokens: .close)
    super.visit(node)
  }

  override func visit(_ node: InitializerDeclSyntax) {
    before(node.firstToken, tokens: .open(.inconsistent, 0))

    if let attributes = node.attributes {
      before(node.firstToken, tokens: .space(size: 0), .open(.consistent, 0))
      after(attributes.lastToken, tokens: .open)
    } else {
      before(node.firstToken, tokens: .space(size: 0), .open(.consistent, 0), .open)
    }

    before(
      node.genericWhereClause?.firstToken,
      tokens: .break, .open(.inconsistent, 0), .break(size: 0), .open(.consistent, 0)
    )
    after(node.genericWhereClause?.lastToken, tokens: .break, .close, .close)

    before(node.throwsOrRethrowsKeyword, tokens: .break)

    if let body = node.body {
      if node.genericWhereClause == nil {
        before(body.leftBrace, tokens: .break)
      }
      after(body.leftBrace, tokens: .close, .close, .break(offset: 2), .open(.consistent, 0))
      before(body.rightBrace, tokens: .break(offset: -2), .close)
    } else {
      // FunctionDecls in protocols won't have bodies, so make sure we close the correct number of
      // groups in that case as well.
      after(node.lastToken, tokens: .close, .close)
    }

    after(node.lastToken, tokens: .close)
    super.visit(node)
  }

  override func visit(_ node: SubscriptDeclSyntax) {
    before(node.firstToken, tokens: .open(.inconsistent, 0))

    if let attributes = node.attributes {
      before(node.firstToken, tokens: .space(size: 0), .open(.consistent, 0))
      after(attributes.lastToken, tokens: .open)
    } else {
      before(node.firstToken, tokens: .space(size: 0), .open(.consistent, 0), .open)
    }

    before(node.result.firstToken, tokens: .break)

    before(
      node.genericWhereClause?.firstToken,
      tokens: .break, .open(.inconsistent, 0), .break(size: 0), .open(.consistent, 0)
    )
    after(node.genericWhereClause?.lastToken, tokens: .break, .close, .close)

    if let accessorBlock = node.accessor {
      if node.genericWhereClause == nil {
        before(accessorBlock.leftBrace, tokens: .break)
      }
      after(accessorBlock.leftBrace, tokens: .close, .close, .break(offset: 2), .open(.consistent, 0))
      before(accessorBlock.rightBrace, tokens: .break(offset: -2), .close)
    } else {
      after(node.lastToken, tokens: .close, .close)
    }

    after(node.lastToken, tokens: .close)
    super.visit(node)
  }

  override func visit(_ node: FunctionSignatureSyntax) {
    before(node.throwsOrRethrowsKeyword, tokens: .break)
    before(node.output?.firstToken, tokens: .break)
    super.visit(node)
  }

  override func visit(_ node: MetatypeTypeSyntax) {
    super.visit(node)
  }

  override func visit(_ node: OptionalTypeSyntax) {
    super.visit(node)
  }

  override func visit(_ node: ProtocolDeclSyntax) {
    if let attributes = node.attributes {
      before(node.firstToken, tokens: .space(size: 0), .open(.consistent, 0))
      after(attributes.lastToken, tokens: .open)
    } else {
      before(node.firstToken, tokens: .space(size: 0), .open(.consistent, 0), .open)
    }

    after(node.protocolKeyword, tokens: .break)
    before(node.members.leftBrace, tokens: .break)
    after(
      node.members.leftBrace,
      tokens: .close, .close, .break(size: 0, offset: 2), .open(.consistent, 0)
    )
    before(node.members.rightBrace, tokens: .break(size: 0, offset: -2), .close)

    super.visit(node)
  }

  override func visit(_ node: SequenceExprSyntax) {
    before(node.firstToken, tokens: .open)
    after(node.lastToken, tokens: .close)
    super.visit(node)
  }

  override func visit(_ node: SuperRefExprSyntax) {
    super.visit(node)
  }

  override func visit(_ node: VariableDeclSyntax) {
    if let attributes = node.attributes {
      before(node.firstToken, tokens: .space(size: 0), .open(.consistent, 0))
      after(attributes.lastToken, tokens: .open)
    } else {
      before(node.firstToken, tokens: .space(size: 0), .open(.consistent, 0), .open)
    }
    after(node.lastToken, tokens: .close, .close)
    after(node.letOrVarKeyword, tokens: .break)
    super.visit(node)
  }

  override func visit(_ node: AsTypePatternSyntax) {
    super.visit(node)
  }

  override func visit(_ node: ExtensionDeclSyntax) {
    if let attributes = node.attributes {
      before(node.firstToken, tokens: .space(size: 0), .open(.consistent, 0))
      after(attributes.lastToken, tokens: .open)
    } else {
      before(node.firstToken, tokens: .space(size: 0), .open(.consistent, 0), .open)
    }

    after(node.extensionKeyword, tokens: .break)

    before(
      node.genericWhereClause?.firstToken,
      tokens: .break, .open(.inconsistent, 0), .break(size: 0), .open(.consistent, 0)
    )
    after(node.genericWhereClause?.lastToken, tokens: .break, .close, .close)

    if node.genericWhereClause == nil {
      before(node.members.leftBrace, tokens: .break)
    }
    after(
      node.members.leftBrace,
      tokens: .close, .close, .break(size: 0, offset: 2), .open(.consistent, 0)
    )
    before(node.members.rightBrace, tokens: .break(size: 0, offset: -2), .close)

    super.visit(node)
  }

  override func visit(_ node: InheritedTypeSyntax) {
    before(node.firstToken, tokens: .open(.inconsistent, 0))
    if let trailingComma = node.trailingComma {
      after(trailingComma, tokens: .close, .break)
    } else {
      after(node.lastToken, tokens: .close)
    }
    super.visit(node)
  }

  override func visit(_ node: IsTypePatternSyntax) {
    after(node.isKeyword, tokens: .break)
    super.visit(node)
  }

  override func visit(_ node: ObjcNamePieceSyntax) {
    super.visit(node)
  }

  override func visit(_ node: PoundFileExprSyntax) {
    super.visit(node)
  }

  override func visit(_ node: PoundLineExprSyntax) {
    super.visit(node)
  }

  override func visit(_ node: StringSegmentSyntax) {
    super.visit(node)
  }

  override func visit(_ node: TypealiasDeclSyntax) {
    super.visit(node)
  }

  override func visit(_ node: AttributedTypeSyntax) {
    after(node.specifier, tokens: .break)
    super.visit(node)
  }

  override func visit(_ node: ExpressionStmtSyntax) {
    super.visit(node)
  }

  override func visit(_ node: IdentifierExprSyntax) {
    super.visit(node)
  }

  override func visit(_ node: NilLiteralExprSyntax) {
    super.visit(node)
  }

  override func visit(_ node: PatternBindingSyntax) {
    before(node.accessor?.firstToken, tokens: .break)
    super.visit(node)
  }

  override func visit(_ node: PoundErrorDeclSyntax) {
    super.visit(node)
  }

  override func visit(_ node: SpecializeExprSyntax) {
    super.visit(node)
  }

  override func visit(_ node: TypeAnnotationSyntax) {
    after(node.colon, tokens: .break(offset: 2))
    super.visit(node)
  }

  override func visit(_ node: UnknownPatternSyntax) {
    super.visit(node)
  }

  override func visit(_ node: CompositionTypeSyntax) {
    super.visit(node)
  }

  override func visit(_ node: DeclarationStmtSyntax) {
    super.visit(node)
  }

  override func visit(_ node: EnumCasePatternSyntax) {
    super.visit(node)
  }

  override func visit(_ node: FallthroughStmtSyntax) {
    super.visit(node)
  }

  override func visit(_ node: ForcedValueExprSyntax) {
    super.visit(node)
  }

  override func visit(_ node: GenericArgumentSyntax) {
    before(node.firstToken, tokens: .open)
    if let trailingComma = node.trailingComma {
      after(trailingComma, tokens: .close, .break)
    } else {
      after(node.lastToken, tokens: .close)
    }
    super.visit(node)
  }

  override func visit(_ node: OptionalPatternSyntax) {
    super.visit(node)
  }

  override func visit(_ node: PoundColumnExprSyntax) {
    super.visit(node)
  }

  override func visit(_ node: RepeatWhileStmtSyntax) {
    after(node.repeatKeyword, tokens: .break)
    after(node.body.leftBrace, tokens: .break(offset: 2), .open(.consistent, 0))
    before(node.body.rightBrace, tokens: .break(offset: -2), .close, .open(.inconsistent, 8))
    before(node.whileKeyword, tokens: .space)
    after(node.whileKeyword, tokens: .space)
    after(node.condition.lastToken, tokens: .close)
    super.visit(node)
  }

  override func visit(_ node: WildcardPatternSyntax) {
    super.visit(node)
  }

  override func visit(_ node: DeclNameArgumentSyntax) {
    super.visit(node)
  }

  override func visit(_ node: FloatLiteralExprSyntax) {
    super.visit(node)
  }

  override func visit(_ node: GenericParameterSyntax) {
    before(node.firstToken, tokens: .open)
    after(node.colon, tokens: .break)
    if let trailingComma = node.trailingComma {
      after(trailingComma, tokens: .close, .break)
    } else {
      after(node.lastToken, tokens: .close)
    }
    super.visit(node)
  }

  override func visit(_ node: PostfixUnaryExprSyntax) {
    super.visit(node)
  }

  override func visit(_ node: PoundWarningDeclSyntax) {
    super.visit(node)
  }

  override func visit(_ node: TupleTypeElementSyntax) {
    before(node.firstToken, tokens: .open)
    after(node.colon, tokens: .break)
    before(node.secondNameWorkaround, tokens: .break)

    if let trailingComma = node.trailingCommaWorkaround {
      after(trailingComma, tokens: .close, .break)
    } else {
      after(node.lastToken, tokens: .close)
    }
    super.visit(node)
  }

  override func visit(_ node: DeinitializerDeclSyntax) {
    super.visit(node)
  }

  override func visit(_ node: ExpressionPatternSyntax) {
    super.visit(node)
  }

  override func visit(_ node: ValueBindingPatternSyntax) {
    after(node.letOrVarKeyword, tokens: .break)
    super.visit(node)
  }

  override func visit(_ node: IdentifierPatternSyntax) {
    super.visit(node)
  }

  override func visit(_ node: InitializerClauseSyntax) {
    before(node.equal, tokens: .break)
    after(node.equal, tokens: .break(offset: 2))

    super.visit(node)
  }

  override func visit(_ node: PoundFunctionExprSyntax) {
    super.visit(node)
  }

  override func visit(_ node: StringLiteralExprSyntax) {
    super.visit(node)
  }

  override func visit(_ node: AssociatedtypeDeclSyntax) {
    super.visit(node)
  }

  override func visit(_ node: BooleanLiteralExprSyntax) {
    super.visit(node)
  }

  override func visit(_ node: ElseIfContinuationSyntax) {
    super.visit(node)
  }

  override func visit(_ node: GenericWhereClauseSyntax) {
    before(node.whereKeyword, tokens: .open(.consistent, 2))
    after(node.whereKeyword, tokens: .break)
    after(node.lastToken, tokens: .close)
    super.visit(node)
  }

  override func visit(_ node: IntegerLiteralExprSyntax) {
    super.visit(node)
  }

  override func visit(_ node: PoundDsohandleExprSyntax) {
    super.visit(node)
  }

  override func visit(_ node: PrefixOperatorExprSyntax) {
    super.visit(node)
  }

  override func visit(_ node: AccessPathComponentSyntax) {
    super.visit(node)
  }

  override func visit(_ node: SameTypeRequirementSyntax) {
    before(node.firstToken, tokens: .open)
    before(node.equalityToken, tokens: .break)
    after(node.equalityToken, tokens: .break)
    if let trailingComma = node.trailingComma {
      after(trailingComma, tokens: .close, .break)
    } else {
      after(node.lastToken, tokens: .close)
    }
    super.visit(node)
  }

  override func visit(_ node: TuplePatternElementSyntax) {
    after(node.trailingComma, tokens: .break)
    super.visit(node)
  }

  override func visit(_ node: MemberTypeIdentifierSyntax) {
    super.visit(node)
  }

  override func visit(_ node: OptionalChainingExprSyntax) {
    super.visit(node)
  }

  override func visit(_ node: SimpleTypeIdentifierSyntax) {
    super.visit(node)
  }

  override func visit(_ node: AvailabilityConditionSyntax) {
    super.visit(node)
  }

  override func visit(_ node: DiscardAssignmentExprSyntax) {
    super.visit(node)
  }

  override func visit(_ node: EditorPlaceholderExprSyntax) {
    super.visit(node)
  }

  override func visit(_ node: SymbolicReferenceExprSyntax) {
    super.visit(node)
  }

  override func visit(_ node: TypeInheritanceClauseSyntax) {
    after(node.colon, tokens: .break(offset: 2))
    before(node.inheritedTypeCollection.firstToken, tokens: .open(.consistent, 0))
    after(node.inheritedTypeCollection.lastToken, tokens: .break(size: 0, offset: -2), .close)
    super.visit(node)
  }

  override func visit(_ node: TypeInitializerClauseSyntax) {
    super.visit(node)
  }

  override func visit(_ node: UnresolvedPatternExprSyntax) {
    super.visit(node)
  }

  override func visit(_ node: CompositionTypeElementSyntax) {
    super.visit(node)
  }

  override func visit(_ node: ConformanceRequirementSyntax) {
    before(node.firstToken, tokens: .open)
    after(node.colon, tokens: .break)
    if let trailingComma = node.trailingComma {
      after(trailingComma, tokens: .close, .break)
    } else {
      after(node.lastToken, tokens: .close)
    }
    super.visit(node)
  }

  override func visit(_ node: StringInterpolationExprSyntax) {
    super.visit(node)
  }

  override func visit(_ node: MatchingPatternConditionSyntax) {
    before(node.firstToken, tokens: .open(.inconsistent, 2))
    after(node.caseKeyword, tokens: .break)
    after(node.lastToken, tokens: .close)
    super.visit(node)
  }

  override func visit(_ node: OptionalBindingConditionSyntax) {
    before(node.firstToken, tokens: .open(.inconsistent, 2))
    after(node.letOrVarKeyword, tokens: .break)
    after(node.lastToken, tokens: .close)
    super.visit(node)
  }

  override func visit(_ node: ImplicitlyUnwrappedOptionalTypeSyntax) {
    super.visit(node)
  }

  override func visit(_ token: UnknownStmtSyntax) {
    appendToken(.verbatim(Verbatim(text: token.description)))
    if let nextToken = token.nextToken, case .eof = nextToken.tokenKind {
      appendToken(.newline)
    }
    // Call to super.visit is not needed here.
  }

  override func visit(_ token: TokenSyntax) {
    extractLeadingTrivia(token)
    if let before = beforeMap[token] {
      tokens += before
    }
    appendToken(.syntax(token))
    extractTrailingComment(token)
    if let afterGroups = afterMap[token] {
      for after in afterGroups.reversed() {
        tokens += after
      }
    }
  }

  private func extractTrailingComment(_ token: TokenSyntax) {
    let nextToken = token.nextToken
    guard let trivia = nextToken?.leadingTrivia,
          let firstPiece = trivia[safe: 0] else {
      return
    }

    switch firstPiece {
    case .lineComment(let text):
      appendToken(.break(size: 2, offset: 2))
      appendToken(.comment(Comment(kind: .line, text: text)))
      if isInContainer(token) {
        appendToken(.newline)
      }

    case .blockComment(let text):
      appendToken(.break(size: 2, offset: 2))
      appendToken(.comment(Comment(kind: .block, text: text)))
      if isInContainer(token) {
        appendToken(.newline)
      }

    default:
      return
    }
  }

  private func isInContainer(_ token: TokenSyntax) -> Bool {
    if token.parent is ArrayElementSyntax || token.parent is DictionaryElementSyntax || token.parent is TupleElementSyntax {
      return true
    }
    return false
  }

  private func extractLeadingTrivia(_ token: TokenSyntax) {
    let isStartOfFile = token.previousToken == nil
    let trivia = token.leadingTrivia

    for (index, piece) in trivia.enumerated() {
      switch piece {
      case .lineComment(let text):
        if index > 0 || isStartOfFile {
          if token.withoutTrivia().text == "}" {
            if let previousToken = token.previousToken,
               previousToken.withoutTrivia().text == "{" {
              // do nothing
            } else {
              appendToken(.newline)
            }
          }

          appendToken(.comment(Comment(kind: .line, text: text)))

          if token.withoutTrivia().text == "}" {
            appendToken(.newline(offset: -2))
          } else {
            appendToken(.newline)
          }
        }

      case .blockComment(let text):
        if index > 0 || isStartOfFile {
          if token.withoutTrivia().text == "}" {
            if let previousToken = token.previousToken,
              previousToken.withoutTrivia().text == "{" {
              // do nothing
            } else {
              appendToken(.newline)
            }
          }

          appendToken(.comment(Comment(kind: .block, text: text)))

          if token.withoutTrivia().text == "}" {
            appendToken(.newline(offset: -2))
          } else {
            appendToken(.newline)
          }
        }

      case .docLineComment(let text):
        appendToken(.comment(Comment(kind: .docLine, text: text)))
        if case .newlines? = trivia[safe: index + 1],
           case .docLineComment? = trivia[safe: index + 2] {
          // do nothing
        } else {
          appendToken(.newline)
        }

      case .docBlockComment(let text):
        appendToken(.comment(Comment(kind: .docBlock, text: text)))
        appendToken(.newline)

      case .newlines(let n), .carriageReturns(let n), .carriageReturnLineFeeds(let n):
        if n > 1 {
          appendToken(.newlines(min(n - 1, config.maximumBlankLines), offset: 0))
        }

      default:
        break
      }
    }
  }

  func appendToken(_ token: Token) {
    if let last = tokens.last {
      switch (last, token) {
      case (.comment(let c1), .comment(let c2))
        where c1.kind == .docLine && c2.kind == .docLine:
        var newComment = c1
        newComment.addText(c2.text)
        tokens[tokens.count - 1] = .comment(newComment)
        return
      default:
        break
      }
    }
    tokens.append(token)
  }
}

extension Syntax {
  /// Creates a pretty-printable token stream for the provided Syntax node.
  func makeTokenStream(configuration: Configuration) -> [Token] {
    return TokenStreamCreator(configuration: configuration).makeStream(from: self)
  }
}

extension Collection {
  subscript(safe index: Index) -> Element? {
    return index < endIndex ? self[index] : nil
  }
}
