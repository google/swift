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

/// Imports must be lexicographically ordered and logically grouped at the top of each source file.
///
/// Lint: If an import appears anywhere other than the beginning of the file it resides in,
///       not lexicographically ordered, or  not in the appropriate import group, a lint error is
///       raised.
///
/// Format: Imports will be reordered and grouped at the top of the file.
///
/// - SeeAlso: https://google.github.io/swift#import-statements
public final class OrderedImports: SyntaxFormatRule {
  public override func visit(_ node: SourceFileSyntax) -> Syntax {
    var fileElements = [CodeBlockItemSyntax]()
    fileElements.append(contentsOf: orderStatements(node))
    let statements = SyntaxFactory.makeCodeBlockItemList(fileElements)
    
    return node.withStatements(statements)
  }
  
  /// Gathers all the statements of the sourcefile, separates the imports in their appropriate
  /// group and sorts each group by lexicographically order.
  private func orderStatements(_ node: SourceFileSyntax) -> [CodeBlockItemSyntax] {
    var fileComment = Trivia()
    var impComment = Trivia()
    var (allImports, allCode) = getAllImports(node.statements)
    
    if let firstImport = allImports.first,
      let firstStatement = node.statements.first,
      firstImport.statement == firstStatement {
      // Extracts the comments of the imports and separates them into file comments
      // and specific comments for the first import statement.
      (fileComment, impComment) = getComments(node.statements.first!)
      allImports[0].statement = replaceTrivia(
        on: node.statements.first!,
        token: node.statements.first?.firstToken,
        leadingTrivia: .newlines(1) + impComment
        ) as! CodeBlockItemSyntax
    }

    let importGroups = groupImports(allImports)
    let sortedImportGroups = sortImports(importGroups)
    var allStatements = joinsImports(sortedImportGroups)
    allStatements.append(contentsOf: allCode)

    // After all the imports have been grouped and sorted, the leading trivia of the new first
    // import has to be rewrite to delete any extra newlines and append any file comment.
    if let firstImport = allStatements.first{
      allStatements[0] = replaceTrivia(
        on: firstImport,
        token: firstImport.firstToken,
        leadingTrivia: fileComment + firstImport.leadingTrivia!.withoutLeadingNewLines()
      ) as! CodeBlockItemSyntax
    }
    
    return allStatements
  }

  /// Groups the imports in their appropiate group  and returns a collection that contains
  /// the three types of imports groups
  func groupImports(_ imports: ([(statement: CodeBlockItemSyntax, type: ImportType)])) ->
    [[CodeBlockItemSyntax]] {
    var importGroups = [[CodeBlockItemSyntax](), [CodeBlockItemSyntax](), [CodeBlockItemSyntax]()]
    for imp in imports {
      // Remove all extra blank lines from the import trivia.
      let importWithCleanTrivia = replaceTrivia(
        on: imp.statement,
        token: imp.statement.firstToken,
        leadingTrivia: removeExtraBlankLines(imp.statement.leadingTrivia!.withoutTrailingSpaces())
        ) as! CodeBlockItemSyntax
      
      importGroups[imp.type.rawValue].append(importWithCleanTrivia)
    }
    return importGroups
  }

  /// Joins the three types of imports into one single colletion and separates
  /// the import groups with one blank line between them.
  func joinsImports(_ statements: [[CodeBlockItemSyntax]]) -> [CodeBlockItemSyntax] {
    return statements.flatMap { (imports: [CodeBlockItemSyntax]) -> [CodeBlockItemSyntax] in
      // Ensures only the first import of each group has the
      // blank line separator.
      if statements.first != imports {
        var newImports = imports
        newImports[0] = replaceTrivia(
          on: imports.first!,
          token: imports.first!.firstToken,
          leadingTrivia: .newlines(1) + imports.first!.leadingTrivia!
          ) as! CodeBlockItemSyntax
        return newImports
      }
      return imports
    }
  }

  /// Sorts all the import groups by lelexicographically order.
  func sortImports(_ imports: [[CodeBlockItemSyntax]]) -> [[CodeBlockItemSyntax]] {
    return imports.filter { !$0.isEmpty }.map { (imports: [CodeBlockItemSyntax]) ->
      [CodeBlockItemSyntax] in
      if !imports.isEmpty && !isSorted(imports) {
        diagnose(.sortImports, on: imports.first)
        return imports.sorted(by: { (l, r) -> Bool in
          return (l.item as! ImportDeclSyntax).path.description <
            (r.item as! ImportDeclSyntax).path.description
        })
      }
      else {
        return imports
      }
    }
  }

  /// Separates all the statements of a file into a collection of the imports
  /// and all the rest of the code.
  func getAllImports(_ statements: CodeBlockItemListSyntax) ->
    ([(statement: CodeBlockItemSyntax, type: ImportType)],
    [CodeBlockItemSyntax]) {
      var readerMode: ImportType?
      var codeEncountered = false
      var allCode = [CodeBlockItemSyntax]()
      // It's assume that most of the staments are not imports.
      allCode.reserveCapacity(statements.count)

      let allImports = statements.compactMap { (statement: CodeBlockItemSyntax) ->
        (statement: CodeBlockItemSyntax, type: ImportType)? in
        if statement.item is ImportDeclSyntax {
          if codeEncountered {
            diagnose(.placeAtTheBeginning(importName: statement.description), on: statement)
          }

          let newReaderMode = classifyImport(statement)
          if readerMode != nil && newReaderMode!.rawValue < readerMode!.rawValue {
            diagnose(
              .orderImportsGroups(
                firstImpType: importTypeName(readerMode!.rawValue),
                secondImpType: importTypeName(newReaderMode!.rawValue)
              ),
              on: statement
            )
          }
          readerMode = newReaderMode
          return (statement, newReaderMode!)
        }
        codeEncountered = true
        allCode.append(statement)
        return nil
      }
      return (allImports, allCode)
  }

  /// If the given trivia contains a blank line between comments, it returns
  /// two trivias, one with all the pieces before the blankline and the other
  /// with the pieces after it
  func getComments(_ firstImp: CodeBlockItemSyntax) -> (fileComments: Trivia, impComments: Trivia) {
    var fileComments = [TriviaPiece]()
    var impComments = [TriviaPiece]()
    guard let firstTokenTrivia = firstImp.leadingTrivia else {
      return (Trivia(pieces: fileComments), Trivia(pieces: impComments))
    }
    var hasFoundBlankLine = false

    for piece in firstTokenTrivia.withoutTrailingSpaces() {
      if !hasFoundBlankLine, case .newlines(let num) = piece, num > 1 {
        hasFoundBlankLine = true
        fileComments.append(piece)
      }
      else if !hasFoundBlankLine {
        fileComments.append(piece)
      }
      else {
        impComments.append(piece)
      }
    }
    return (Trivia(pieces: fileComments), Trivia(pieces: impComments))
  }

  /// Return the given trivia without any set of consecutive blank lines
  func removeExtraBlankLines(_ trivia: Trivia) -> Trivia {
    var pieces = [TriviaPiece]()
    for piece in trivia.withoutTrailingSpaces() {
      if case .newlines(let num) = piece, num > 1 {
        pieces.append(.newlines(1))
      }
      else {
        pieces.append(piece)
      }
    }
    return Trivia(pieces: pieces)
  }

  enum ImportType: Int {
    case regularImport = 0
    case individualImport
    case testableImport
  }

  /// Indicates to which import type those the given import belongs.
  func classifyImport(_ impStatement: CodeBlockItemSyntax) -> ImportType? {
    guard let importToken = impStatement.firstToken else {return nil}
    guard let nextToken = importToken.nextToken else {return nil}
  
    if importToken.tokenKind == .atSign && nextToken.text == "testable" {
      return ImportType.testableImport
    }
    if nextToken.tokenKind != .identifier(nextToken.text) {
      return ImportType.individualImport
    }
    return ImportType.regularImport
  }

  /// Return the name of the given import group type.
  func importTypeName(_ type: Int) -> String {
    switch type {
    case 0:
      return "regular imports"
    case 1:
      return "Individual declaration imports"
    default:
      return "@testable imports"
    }
  }

  /// Returns a bool indicating if the given collection of imports is ordered by
  /// lexicographically order.
  func isSorted(_ imports: [CodeBlockItemSyntax]) -> Bool {
    for index in 1..<imports.count {
      if (imports[index - 1].item as! ImportDeclSyntax).path.description > (imports[index].item as! ImportDeclSyntax).path.description {
        return false
      }
    }
    return true
  }
}

extension Diagnostic.Message {
  static func placeAtTheBeginning(importName: String) -> Diagnostic.Message {
    return Diagnostic.Message(.warning, "Place the \(importName) at the beginning of the file.")
  }
  
  static func orderImportsGroups(firstImpType: String, secondImpType: String) -> Diagnostic.Message {
    return Diagnostic.Message(.warning, "Place the \(secondImpType) after the \(firstImpType).")
  }

  static let sortImports =
    Diagnostic.Message(.warning, "Sort the imports by lexicographically order.")
}
