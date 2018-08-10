import Core
import Foundation
import SwiftSyntax

/// Parameterized attributes must be written on individual lines, ordered lexicographically.
///
/// Lint: Parameterized attributes not on an individual line will yield a lint error.
///       Parameterized attributes not in lexicographic order will yield a lint error.
///
/// Format: Parameterized attributes will be placed on individual lines in lexicographic order.
///
/// TODO: Handle/format attributes without parameters?
///
/// - SeeAlso: https://google.github.io/swift#attributes
public final class ParameterizedAttributesOnNewLines: SyntaxFormatRule {

  var nextTok: TokenSyntax? = nil
  var nextTokIdx: Int? = nil
  var numOfSpaces: Int? = nil

  public override func visit(_ node: AttributeListSyntax) -> Syntax {

    let firstAttribute = node[0]
    let firstLeadingTrivia = firstAttribute.leadingTrivia ?? []
    nextTok = node.nextToken
    nextTokIdx = node.nextToken?.indexInParent
    numOfSpaces = retrieveIndentNumber(trivia: firstLeadingTrivia)
    let topBlankLines = countTopBlankLines(trivia: firstLeadingTrivia)

    var attributes: [AttributeSyntax] = []
    attributes.append(contentsOf: node)

    // If the first attribute contains documentation in leading trivia, transfer to the new first
    // attribute after sorting
    if containsDocComments(trivia: firstLeadingTrivia) {
      attributes[0] = replaceTrivia(on: attributes[0],
                                    token: attributes[0].firstToken,
                                    leadingTrivia: []) as! AttributeSyntax
      attributes = attributes.sorted(by: { attributeDescription(attribute: $0) <
                                           attributeDescription(attribute: $1) })
      attributes[0] = replaceTrivia(on: attributes[0],
                                    token: attributes[0].firstToken,
                                    leadingTrivia: firstLeadingTrivia +
                                                   (attributes[0].leadingTrivia ?? []))
                                    as! AttributeSyntax
    } else {
      attributes = attributes.sorted(by: { attributeDescription(attribute: $0) <
                                           attributeDescription(attribute: $1) })
    }

    for (idx, attribute) in attributes.enumerated() {
      guard attribute.argument != nil else { continue }
      let leadingTrivia = attribute.leadingTrivia ?? []
      let indent = numOfSpaces != nil ? Trivia.spaces(numOfSpaces!) : []
      let newLeadingTrivia = reformatTrivia(trivia: leadingTrivia,
                                            newLineWithIndent: .newlines(1) + indent,
                                            topBlankLines: idx == 0 ? topBlankLines : 0)
      var newAttribute = replaceTrivia(on: attribute,
                                  token: attribute.firstToken,
                                  leadingTrivia: newLeadingTrivia) as! AttributeSyntax
      newAttribute = replaceTrivia(on: newAttribute,
                                   token: newAttribute.lastToken,
                                   trailingTrivia: []) as! AttributeSyntax
      attributes[idx] = newAttribute
    }
    return SyntaxFactory.makeAttributeList(attributes)
  }

  public override func visit(_ token: TokenSyntax) -> Syntax {
    // safe checks ?
    guard token == nextTok else { return token }
    guard token.indexInParent == nextTokIdx else { return token }
    guard !token.leadingTrivia.containsNewlines else { return token }
    let indent = Trivia.spaces(numOfSpaces ?? 0)
    return token.withLeadingTrivia(.newlines(1) +
                                   (indent.numberOfSpaces > 0 ? indent : []))
  }

  func retrieveIndentNumber(trivia: Trivia) -> Int? {
    for piece in trivia.reversed() {
      if case .spaces(let n) = piece { return n }
    }
    return nil
  }

  func countTopBlankLines(trivia: Trivia) -> Int {
    var numBlankLines = 0
    for piece in trivia {
      switch piece {
      case .lineComment, .docLineComment, .blockComment, .docBlockComment:
        return numBlankLines
      case .newlines(let n):
        numBlankLines += n
      default:
        continue
      }
    }
    return numBlankLines
  }

  func attributeDescription(attribute: AttributeSyntax) -> String {
    var description = "\(attribute)"
    guard let atIndx = description.firstIndex(of: "@") else { return description }
    description = String(description.suffix(from: atIndx))
    description = description.trimmingCharacters(in: .whitespacesAndNewlines)
    return description
  }
  
  func containsDocComments(trivia: Trivia) -> Bool {
    for piece in trivia {
      if case .docLineComment = piece { return true }
    }
    return false
  }
  
  func reformatTrivia(trivia: Trivia,
                      newLineWithIndent: Trivia,
                      topBlankLines: Int) -> Trivia {
    var newTrivia = [TriviaPiece]()
    var comments = [TriviaPiece]()
    for piece in trivia {
      switch piece {
      case .lineComment, .docLineComment, .blockComment, .docBlockComment:
        comments.append(piece)
      default:
        continue
      }
    }

    guard comments.count > 0 else { return newLineWithIndent }
    if topBlankLines > 0 {
      newTrivia.append(.newlines(topBlankLines - 1))
      newTrivia.append(contentsOf: newLineWithIndent)
    } else { newTrivia.append(contentsOf: newLineWithIndent) }
    for piece in comments {
      newTrivia.append(piece)
      newTrivia.append(contentsOf: newLineWithIndent)
    }

    return Trivia(pieces: newTrivia)
  }
}
