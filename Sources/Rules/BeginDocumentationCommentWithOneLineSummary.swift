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

/// All documentation comments must begin with a one-line summary of the declaration.
///
/// Lint: If a comment does not begin with a single-line summary, a lint error is raised.
///
/// - SeeAlso: https://google.github.io/swift#single-sentence-summary
public final class BeginDocumentationCommentWithOneLineSummary:  SyntaxLintRule {
  override public func visit(_ node: FunctionDeclSyntax) {
    diagnoseDocComments(node)
  }

  override public func visit(_ node: EnumDeclSyntax) {
    diagnoseDocComments(node)
  }

  override public func visit(_ node: InitializerDeclSyntax) {
    diagnoseDocComments(node)
  }

  override public func visit(_ node: DeinitializerDeclSyntax) {
    diagnoseDocComments(node)
  }

  override public func visit(_ node: SubscriptDeclSyntax) {
    diagnoseDocComments(node)
  }

  override public func visit(_ node: ClassDeclSyntax) {
    diagnoseDocComments(node)
  }

  override public func visit(_ node: VariableDeclSyntax) {
    diagnoseDocComments(node)
  }

  override public func visit(_ node: StructDeclSyntax) {
    diagnoseDocComments(node)
  }

  override public func visit(_ node: ProtocolDeclSyntax) {
    diagnoseDocComments(node)
  }

  override public func visit(_ node: TypealiasDeclSyntax) {
    diagnoseDocComments(node)
  }

  /// Diagnose documentation comments that don't start
  /// with one sentence summary.
  func diagnoseDocComments(_ decl: DeclSyntax) {
    guard let commentText = decl.docComment else { return }
    let docComments = commentText.components(separatedBy: "\n")
    guard let firstPart = firstParagraph(docComments) else { return }

    let commentSentences = sentences(in: firstPart)
    if commentSentences.count > 1 {
      diagnose(.docCommentRequiresOneSentenceSummary(commentSentences.first!), on: decl)
    }
  }

  /// Returns the text of the first part of the comment,
  func firstParagraph(_ comments: [String]) -> String? {
    var text = [String]()
    var index = 0
    while index < comments.count  &&
      comments[index] != "*" &&
      comments[index] != "" {
      text.append(comments[index])
      index = index + 1
    }
    return comments.isEmpty ? nil : text.joined(separator:" ")
  }

  /// Returns all the sentences in the given text.
  func sentences(in text: String) -> [String] {
    var sentences = [String]()
    if #available(OSX 10.13, *) { /// add linux condition
      let tagger = NSLinguisticTagger(tagSchemes: [.tokenType], options: 0)
      tagger.string = text
      let range = NSRange(location: 0, length: text.utf16.count)
      let options: NSLinguisticTagger.Options = [.omitWhitespace, .omitOther]
      tagger.enumerateTags(
        in: range,
        unit: .sentence,
        scheme: .tokenType,
        options: options
      ) {_, tokenRange, _ in
        let sentence = (text as NSString).substring(with: tokenRange)
        sentences.append(sentence)
      }
    } else {
      return text.components(separatedBy: ". ")
    }
    return sentences
  }
}

extension Diagnostic.Message {
  static func docCommentRequiresOneSentenceSummary(_ firstSentence: String) -> Diagnostic.Message {
    let sentenceWithoutExtraSpaces = firstSentence.trimmingCharacters(in: .whitespacesAndNewlines)
    return .init(
      .warning,
      "add a blank comment line after this sentence: \"\(sentenceWithoutExtraSpaces)\""
    )
  }
}
