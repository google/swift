import Core
import Foundation
import SwiftSyntax

/// At least one blank line between each member of a type.
///
/// Optionally, declarations of single-line properties can be ignored.
///
/// Lint: If more than the maximum number of blank lines appear, a lint error is raised.
///       If there are no blank lines between members, a lint error is raised.
///
/// Format: Declarations with no blank lines will have a blank line inserted.
///         Declarations with more than the maximum number of blank lines will be reduced to the
///         maximum number of blank lines.
///
/// Configuration: maximumBlankLines, blankLineBetweenMembers.ignoreSingleLineProperties
///
/// - SeeAlso: https://google.github.io/swift#vertical-whitespace
public final class BlankLineBetweenMembers: SyntaxFormatRule {
  public override func visit(_ node: MemberDeclBlockSyntax) -> Syntax {
    var membersList = [MemberDeclListItemSyntax]()
    let maxBlankLines = context.configuration.maximumBlankLines
    
    // Iterates through all the declaration of the member, to ensure that the declarations have
    // at least on blank line and doesn't exceed the maximum number of blanklines.
    for member in node.members {
      let currentMember = checkForNestedMembers(member)
      guard let memberTrivia = currentMember.leadingTrivia else { continue }
      // A blank line needs two newlines to begin.
      let numBlanklines = countNumNewLines(memberTrivia, withoutComments: true) - 1
      
      if numBlanklines > maxBlankLines {
        diagnose(.removeBlankLines(count: numBlanklines - maxBlankLines,
                                   memberDesc: currentMember.description),on: currentMember)
        let correctTrivia = getCommentsAndIdentation(memberTrivia, numNewLines: maxBlankLines + 1)
        let newMember = replaceTrivia(on: currentMember, token: currentMember.firstToken!,
                                      leadingTrivia: correctTrivia) as! MemberDeclListItemSyntax
        membersList.append(newMember)
      }
      else if !ignoreItem(item: currentMember), numBlanklines == 0 {
        let numNewLines = member != node.members.first ? 2 : 1
        diagnose(.addBlankLines(memberDesc: currentMember.description), on: currentMember)
        let correctTrivia = getCommentsAndIdentation(memberTrivia, numNewLines: numNewLines)
        let newMember = replaceTrivia(on: currentMember, token: currentMember.firstToken!,
                                      leadingTrivia: correctTrivia) as! MemberDeclListItemSyntax
        
        membersList.append(newMember)
      }
      else {
        membersList.append(member)
      }
    }
    return node.withMembers(SyntaxFactory.makeMemberDeclList(membersList))
  }
  
  /// Indicates if a declaration has to be ignored by checking if a declaration
  /// is single line and if the format is configured to ignore single lines.
  func ignoreItem(item: MemberDeclListItemSyntax) -> Bool {
    guard let firstToken = item.firstToken else { return false }
    guard let lastToken = item.lastToken else { return false }
    let numNewLines = countNumNewLines(firstToken.leadingTrivia, withoutComments: false)
    
    // The position of a token is determined by it's leading trivia,
    // to calculate the exact position of a token
    let isSingleLine = firstToken.position.line + numNewLines == lastToken.position.line
    let ignoreLine = context.configuration.blankLineBetweenMembers.ignoreSingleLineProperties
    return isSingleLine && ignoreLine
  }
  
  /// Recursively ensures all nested member types follows the BlankLineBetweenMembers rule.
  func checkForNestedMembers(_ member: MemberDeclListItemSyntax) -> MemberDeclListItemSyntax {
    if let nestedEnum = member.decl as? EnumDeclSyntax {
      let nestedMembers = visit(nestedEnum.members)
      let newDecl = nestedEnum.withMembers(nestedMembers as? MemberDeclBlockSyntax)

      return member.withDecl(newDecl)
    }
    else if let nestedStruct = member.decl as? StructDeclSyntax {
      let nestedMembers = visit(nestedStruct.members)
      let newDecl = nestedStruct.withMembers(nestedMembers as? MemberDeclBlockSyntax)

      return member.withDecl(newDecl)
    }
    else if let nestedClass = member.decl as? ClassDeclSyntax {
      let nestedMembers = visit(nestedClass.members)
      let newDecl = nestedClass.withMembers(nestedMembers as? MemberDeclBlockSyntax)
      
      return member.withDecl(newDecl)
    }
    else if let nestedExtension = member.decl as? ExtensionDeclSyntax {
      let nestedMembers = visit(nestedExtension.members)
      let newDecl = nestedExtension.withMembers(nestedMembers as? MemberDeclBlockSyntax)
      
      return member.withDecl(newDecl)
    }
    
    return member
  }
}

/// Returns the given trivia with the correct indentation and number of
/// newlines preserving comments.
func getCommentsAndIdentation(_ trivia: Trivia, numNewLines: Int) -> Trivia {
  var pieces = [TriviaPiece]()
  pieces.append(.newlines(numNewLines))
  var hasFoundComment = false
  
  for piece in trivia {
    if case .lineComment(_) = piece {
      pieces.append(piece)
      hasFoundComment = true
    }
    else if case .docLineComment(_) = piece {
      pieces.append(piece)
      hasFoundComment = true
    }
    else if case .blockComment(_) = piece {
      pieces.append(piece)
      hasFoundComment = true
    }
    else if case .docBlockComment(_) = piece {
      pieces.append(piece)
      hasFoundComment = true
    }
    else if case .spaces(_) = piece {
      pieces.append(piece)
    }
    else if hasFoundComment, case .newlines(_) = piece {
      pieces.append(piece)
    }
  }
  return Trivia.init(pieces: pieces)
}

/// Returns the number of newlines in the given trivia.
/// If withoutComments is true it returns the number of newlines until
/// it finds a comment.
func countNumNewLines(_ trivia: Trivia, withoutComments: Bool) -> Int {
  var count = 0
  for piece in trivia {
    if case .newlines(let num) = piece {
      count += num
    }
    else if withoutComments, case .lineComment(_) = piece {
      return count
    }
    else if withoutComments, case .docLineComment(_) = piece {
      return count
    }
    else if withoutComments, case .blockComment(_) = piece {
      return count
    }
    else if withoutComments, case .docBlockComment(_) = piece {
      return count
    }
  }
  return count
}

extension Diagnostic.Message {
  static func addBlankLines(memberDesc: String) -> Diagnostic.Message {
    print("add one blank line before \(memberDesc)")
    return Diagnostic.Message(.warning, "add one blank line before: \(memberDesc)")
  }
  
  static func removeBlankLines(count: Int, memberDesc: String) -> Diagnostic.Message {
    let ending = count > 1 ? "s" : ""
    print("remove \(count) blank line\(ending) before \(memberDesc)")
    return Diagnostic.Message(.warning, "remove \(count) blank line\(ending) before: \(memberDesc)")
  }
}
