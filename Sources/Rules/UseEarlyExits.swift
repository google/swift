import Core
import Foundation
import SwiftSyntax

/// Early exits should be used whenever possible.
///
/// Practically, this means that `if ... else return/throw/break` constructs should be replaced by
/// `guard ... else { return/throw/break }` constructs in order to keep indentation levels low.
///
/// Lint: `if ... else return/throw/break` constructs will yield a lint error.
///
/// Format: `if ... else return/throw/break` constructs will be replaced with equivalent
///         `guard ... else { return/throw/break }` constructs.
///         TODO(abl): replace implicit guards as well?
///
/// - SeeAlso: https://google.github.io/swift#guards-for-early-exits
public final class UseEarlyExits: SyntaxFormatRule {
  
  public override func visit(_ node: CodeBlockSyntax) -> Syntax {
    
    var newItems: [CodeBlockItemSyntax] = []
    for statement in node.statements {
      guard let ifStmt = statement.item as? IfStmtSyntax else { return node }
      guard let elseStmt = ifStmt.elseBody else { return node }
      guard let elseBody = elseStmt as? CodeBlockSyntax else { return node }

      if elseContainsControlStmt(elseStmt: elseStmt) {
        diagnose(.useGuardStmt, on: ifStmt)
        guard let moveDeletedIfCode = visit(
          ifStmt.body.withLeftBrace(nil).withRightBrace(nil)) as? CodeBlockSyntax else { continue }
        guard let moveElseBody = visit(elseBody) as? CodeBlockSyntax else { continue }
        
        let ifConditions = ifStmt.conditions
        let formattedGuardKeyword = SyntaxFactory.makeGuardKeyword(
          leadingTrivia: ifStmt.ifKeyword.leadingTrivia,
          trailingTrivia: .spaces(1))
        let newGuardStmt = SyntaxFactory.makeGuardStmt(
          guardKeyword: formattedGuardKeyword,
          conditions: ifConditions,
          elseKeyword: SyntaxFactory.makeElseKeyword(trailingTrivia: .spaces(1)),
          body: moveElseBody)
        newItems.append(
          SyntaxFactory.makeCodeBlockItem(item: newGuardStmt,
                                          semicolon: nil)
        )
        newItems.append(
          SyntaxFactory.makeCodeBlockItem(item: moveDeletedIfCode,
                                          semicolon: nil)
        )
      }
    }

    let newNode = node.withStatements(SyntaxFactory.makeCodeBlockItemList(newItems))
    return super.visit(newNode)
  }

  func elseContainsControlStmt(elseStmt: Syntax) -> Bool {
    for child in elseStmt.children {
      guard let codeBlockList = child as? CodeBlockItemListSyntax else { continue }
      guard let last = codeBlockList.child(at: codeBlockList.count - 1) as?
        CodeBlockItemSyntax else { continue }

      switch last.item {
      case is ReturnStmtSyntax, is ThrowStmtSyntax, is BreakStmtSyntax, is ContinueStmtSyntax:
        return true
      default:
        continue
      }
    }
    return false
  }
}

extension Diagnostic.Message {
  static let useGuardStmt = Diagnostic.Message(.warning, "replace with guard statement")
}
