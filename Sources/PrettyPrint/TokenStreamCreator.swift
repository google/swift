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

import Configuration
import Core
import SwiftSyntax

private class FindChildScope: SyntaxVisitor {
  var found = false
  override func visit(_ node: CodeBlockSyntax) {
    found = true
  }
  override func visit(_ node: SwitchStmtSyntax) {
    found = true
  }
  func findChildScope(in items: CodeBlockItemListSyntax) -> Bool {
    for child in items {
      visit(child)
      if found { return true }
    }
    return false
  }
}

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

  override func visitPre(_ node: Syntax) {}

  override func visit(_ node: DeclNameArgumentsSyntax) {
    super.visit(node)
  }

  override func visit(_ node: BinaryOperatorExprSyntax) {
    super.visit(node)
  }

  override func visit(_ node: TupleExprSyntax) {
    super.visit(node)
  }

  override func visit(_ node: ArrayExprSyntax) {
    super.visit(node)
  }

  override func visit(_ node: DictionaryExprSyntax) {
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

  override func visit(_ node: ClosureCaptureSignatureSyntax) {
    super.visit(node)
  }

  override func visit(_ node: ClosureExprSyntax) {
    super.visit(node)
  }

  override func visit(_ node: FunctionCallExprSyntax) {
    super.visit(node)
  }

  override func visit(_ node: SubscriptExprSyntax) {
    super.visit(node)
  }

  override func visit(_ node: ExpressionSegmentSyntax) {
    super.visit(node)
  }

  override func visit(_ node: SwitchCaseLabelSyntax) {
    super.visit(node)
  }

  override func visit(_ node: SwitchDefaultLabelSyntax) {
    super.visit(node)
  }

  override func visit(_ node: ObjcKeyPathExprSyntax) {
    super.visit(node)
  }

  override func visit(_ node: AssignmentExprSyntax) {
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
    after(node.enumKeyword, tokens: .break)

    before(node.genericWhereClause?.firstToken, tokens: .break, .open(.consistent, 0))
    after(node.genericWhereClause?.lastToken, tokens: .break, .close)

    if node.genericWhereClause == nil {
      before(node.members.leftBrace, tokens: .break)
    }
    after(node.members.leftBrace, tokens: .break(size: 0, offset: 2), .open(.consistent, 0))
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

  override func visit(_ node: IfConfigClauseSyntax) {
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

  func shouldAddOpenCloseNewlines(_ node: Syntax) -> Bool {
    if node is AccessorListSyntax { return true }
    guard let list = node as? CodeBlockItemListSyntax else {
      return false
    }
    if list.count > 1 { return true }
    return FindChildScope().findChildScope(in: list)
  }

  override func visit(_ node: AccessorBlockSyntax) {
    super.visit(node)
  }

  override func visit(_ node: CodeBlockSyntax) {
    for i in 0..<(node.statements.count - 1) {
      after(node.statements[i].lastToken, tokens: .newline)
    }
    super.visit(node)
  }

  override func visit(_ node: CodeBlockItemSyntax) {
    if !(node.parent?.parent is CodeBlockSyntax) {
      after(node.lastToken, tokens: .newline)
    }
    super.visit(node)
  }

  override func visit(_ node: SwitchCaseSyntax) {
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

  override func visit(_ node: DictionaryTypeSyntax) {
    super.visit(node)
  }

  override func visit(_ node: TupleTypeSyntax) {
    after(node.leftParen, tokens: .open(.consistent, 2), .break(size: 0))
    before(node.rightParen, tokens: .break(size: 0), .close)
    for index in 0..<(node.elements.count - 1) {
      after(node.elements[index].lastToken, tokens: .break)
    }
    super.visit(node)
  }

  override func visit(_ node: FunctionTypeSyntax) {
    super.visit(node)
  }

  override func visit(_ node: GenericArgumentClauseSyntax) {
    super.visit(node)
  }

  override func visit(_ node: TuplePatternSyntax) {
    after(node.leftParen, tokens: .open(.consistent, 2), .break(size: 0))
    before(node.rightParen, tokens: .break(size: 0), .close)
    super.visit(node)
  }

  override func visit(_ node: AsExprSyntax) {
    super.visit(node)
  }

  override func visit(_ node: DoStmtSyntax) {
    super.visit(node)
  }

  override func visit(_ node: IfStmtSyntax) {
    before(node.ifKeyword, tokens: .open(.inconsistent, 3))
    after(node.ifKeyword, tokens: .break)
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
    super.visit(node)
  }

  override func visit(_ node: TryExprSyntax) {
    super.visit(node)
  }

  override func visit(_ node: CaseItemSyntax) {
    super.visit(node)
  }

  override func visit(_ node: TypeExprSyntax) {
    super.visit(node)
  }

  override func visit(_ node: ArrowExprSyntax) {
    super.visit(node)
  }

  override func visit(_ node: AttributeSyntax) {
    super.visit(node)
  }

  override func visit(_ node: BreakStmtSyntax) {
    super.visit(node)
  }

  override func visit(_ node: ClassDeclSyntax) {
    after(node.classKeyword, tokens: .break)

    before(node.genericWhereClause?.firstToken, tokens: .break, .open(.consistent, 0))
    after(node.genericWhereClause?.lastToken, tokens: .break, .close)

    if node.genericWhereClause == nil {
      before(node.members.leftBrace, tokens: .break)
    }
    after(node.members.leftBrace, tokens: .break(size: 0, offset: 2), .open(.consistent, 0))
    before(node.members.rightBrace, tokens: .break(size: 0, offset: -2), .close)

    super.visit(node)
  }

  override func visit(_ node: DeferStmtSyntax) {
    super.visit(node)
  }

  override func visit(_ node: ElseBlockSyntax) {
    super.visit(node)
  }

  override func visit(_ node: ForInStmtSyntax) {
    super.visit(node)
  }

  override func visit(_ node: GuardStmtSyntax) {
    super.visit(node)
  }

  override func visit(_ node: InOutExprSyntax) {
    super.visit(node)
  }

  override func visit(_ node: ThrowStmtSyntax) {
    super.visit(node)
  }

  override func visit(_ node: WhileStmtSyntax) {
    super.visit(node)
  }

  override func visit(_ node: ImportDeclSyntax) {
    super.visit(node)
  }

  override func visit(_ node: ReturnStmtSyntax) {
    before(node.firstToken, tokens: .open)
    after(node.returnKeyword, tokens: .break)
    after(node.lastToken, tokens: .close)
    super.visit(node)
  }

  override func visit(_ node: StructDeclSyntax) {
    after(node.structKeyword, tokens: .break)

    before(node.genericWhereClause?.firstToken, tokens: .break, .open(.consistent, 0))
    after(node.genericWhereClause?.lastToken, tokens: .break, .close)

    if node.genericWhereClause == nil {
      before(node.members.leftBrace, tokens: .break)
    }
    after(node.members.leftBrace, tokens: .break(size: 0, offset: 2), .open(.consistent, 0))
    before(node.members.rightBrace, tokens: .break(size: 0, offset: -2), .close)

    super.visit(node)
  }

  override func visit(_ node: SwitchStmtSyntax) {
    super.visit(node)
  }

  override func visit(_ node: CatchClauseSyntax) {
    super.visit(node)
  }

  override func visit(_ node: DotSelfExprSyntax) {
    super.visit(node)
  }

  override func visit(_ node: KeyPathExprSyntax) {
    super.visit(node)
  }

  override func visit(_ node: TernaryExprSyntax) {
    super.visit(node)
  }

  override func visit(_ node: WhereClauseSyntax) {
    super.visit(node)
  }

  override func visit(_ node: AccessorDeclSyntax) {
    super.visit(node)
  }

  override func visit(_ node: ArrayElementSyntax) {
    super.visit(node)
  }

  override func visit(_ node: ClosureParamSyntax) {
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
    after(node.funcKeyword, tokens: .break)

    before(node.genericWhereClause?.firstToken, tokens: .break, .open(.consistent, 0))
    after(node.genericWhereClause?.lastToken, tokens: .break, .close)

    if let body = node.body {
      if node.genericWhereClause == nil {
        before(body.leftBrace, tokens: .break)
      }
      after(body.leftBrace, tokens: .break(offset: 2), .open(.consistent, 0))
      before(body.rightBrace, tokens: .break(offset: -2), .close)
    }

    super.visit(node)
  }

  override func visit(_ node: FunctionSignatureSyntax) {
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
    super.visit(node)
  }

  override func visit(_ node: SequenceExprSyntax) {
    for index in 0..<(node.elements.count - 1) {
      after(node.elements[index].lastToken, tokens: .break)
    }
    super.visit(node)
  }

  override func visit(_ node: SuperRefExprSyntax) {
    super.visit(node)
  }

  override func visit(_ node: TupleElementSyntax) {
    after(node.trailingComma, tokens: .break)
    super.visit(node)
  }

  override func visit(_ node: VariableDeclSyntax) {
    before(node.firstToken, tokens: .open(.inconsistent, 2))
    after(node.lastToken, tokens: .close)
    after(node.letOrVarKeyword, tokens: .break)
    super.visit(node)
  }

  override func visit(_ node: AsTypePatternSyntax) {
    super.visit(node)
  }

  override func visit(_ node: ExtensionDeclSyntax) {
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

  override func visit(_ node: SubscriptDeclSyntax) {
    super.visit(node)
  }

  override func visit(_ node: TypealiasDeclSyntax) {
    super.visit(node)
  }

  override func visit(_ node: AttributedTypeSyntax) {
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
    super.visit(node)
  }

  override func visit(_ node: PoundErrorDeclSyntax) {
    super.visit(node)
  }

  override func visit(_ node: SpecializeExprSyntax) {
    super.visit(node)
  }

  override func visit(_ node: TypeAnnotationSyntax) {
    after(node.colon, tokens: .break)
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
    super.visit(node)
  }

  override func visit(_ node: InitializerDeclSyntax) {
    super.visit(node)
  }

  override func visit(_ node: OptionalPatternSyntax) {
    super.visit(node)
  }

  override func visit(_ node: PoundColumnExprSyntax) {
    super.visit(node)
  }

  override func visit(_ node: RepeatWhileStmtSyntax) {
    super.visit(node)
  }

  override func visit(_ node: WildcardPatternSyntax) {
    super.visit(node)
  }

  override func visit(_ node: ClosureSignatureSyntax) {
    super.visit(node)
  }

  override func visit(_ node: ConditionElementSyntax) {
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
    super.visit(node)
  }

  override func visit(_ node: DeinitializerDeclSyntax) {
    super.visit(node)
  }

  override func visit(_ node: DictionaryElementSyntax) {
    super.visit(node)
  }

  override func visit(_ node: ExpressionPatternSyntax) {
    super.visit(node)
  }

  override func visit(_ node: ValueBindingPatternSyntax) {
    super.visit(node)
  }

  override func visit(_ node: IdentifierPatternSyntax) {
    super.visit(node)
  }

  override func visit(_ node: InitializerClauseSyntax) {
    before(node.equal, tokens: .break)
    after(node.equal, tokens: .break)
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

  override func visit(_ node: ClosureCaptureItemSyntax) {
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

  override func visit(_ node: FunctionCallArgumentSyntax) {
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
    super.visit(node)
  }

  override func visit(_ node: OptionalBindingConditionSyntax) {
    super.visit(node)
  }

  override func visit(_ node: ImplicitlyUnwrappedOptionalTypeSyntax) {
    super.visit(node)
  }

  override func visit(_ token: TokenSyntax) {
    breakDownTrivia(token.leadingTrivia, before: token)
    if let before = beforeMap[token] {
      tokens += before
    }
    appendToken(.syntax(token))
    if let afterGroups = afterMap[token] {
      for after in afterGroups.reversed() {
        tokens += after
      }
    }
    breakDownTrivia(token.trailingTrivia)
  }

  func appendToken(_ token: Token) {
    if let last = tokens.last {
      switch (last, token) {
      case (.comment(let c1, _), .comment(let c2, _))
        where c1.kind == .docLine && c2.kind == .docLine:
        var newComment = c1
        newComment.addText(c2.text)
        tokens[tokens.count - 1] = .comment(newComment, hasTrailingSpace: false)
        return
      default:
        break
      }
    }
    tokens.append(token)
  }

  private func shouldAddNewlineBefore(_ token: TokenSyntax?) -> Bool {
    guard let token = token, let before = beforeMap[token] else { return false }
    for item in before {
      if case .newlines = item { return false }
    }
    return true
  }

  private func breakDownTrivia(_ trivia: Trivia, before: TokenSyntax? = nil) {
    for (offset, piece) in trivia.enumerated() {
      switch piece {
      case .lineComment(let text):
        appendToken(.comment(Comment(kind: .line, text: text), hasTrailingSpace: false))
        if case .newlines? = trivia[safe: offset + 1],
           case .lineComment? = trivia[safe: offset + 2] {
          /* do nothing */
        } else {
          appendToken(.newline)
        }
      case .docLineComment(let text):
        appendToken(.comment(Comment(kind: .docLine, text: text), hasTrailingSpace: false))
        if case .newlines? = trivia[safe: offset + 1],
           case .docLineComment? = trivia[safe: offset + 2] {
          /* do nothing */
        } else {
          appendToken(.newline)
        }
      case .blockComment(let text), .docBlockComment(let text):
        var hasTrailingSpace = false
        var hasTrailingNewline = false

        // Detect if a newline or trailing space comes after this comment and preserve it.
        if let next = trivia[safe: offset + 1] {
          switch next {
          case .newlines, .carriageReturns, .carriageReturnLineFeeds:
            hasTrailingNewline = true
          case .spaces, .tabs:
            hasTrailingSpace = true
          default:
            break
          }
        }

        let commentKind: Comment.Kind
        if case .blockComment = piece {
          commentKind = .block
        } else {
          commentKind = .docBlock
        }
        let comment = Comment(kind: commentKind, text: text)
        appendToken(.comment(comment, hasTrailingSpace: hasTrailingSpace))
        if hasTrailingNewline {
          appendToken(.newline)
        }
      case .newlines(let n), .carriageReturns(let n), .carriageReturnLineFeeds(let n):
        if n > 1 {
          appendToken(.newlines(min(n - 1, config.maximumBlankLines), offset: 0))
        }
      default:
        break
      }
    }
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
