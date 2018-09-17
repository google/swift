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

/// A single space is required after every keyword that precedes another token on the same line.
///
/// Lint: If a keyword appears before a token on the same line without a space between them, a lint
///       error is raised.
///
/// Format: A single space will be inserted between keywords and other same-line tokens.
///
/// - SeeAlso: https://google.github.io/swift#horizontal-whitespace
public final class OneSpaceAfterKeywords: SyntaxFormatRule {
  public override func visit(_ token: TokenSyntax) -> Syntax {
    guard let nextToken = token.nextToken else { return token }
    
    // Keywords own their trailing spaces, so ensure it only has 1, if there's
    // another token on the same line.
    if token.tokenKind.isTypeKeyword,
      (nextToken.tokenKind.isTypeKeyword || isIdentifier(nextToken.tokenKind)),
       !nextToken.leadingTrivia.containsNewlines {
      let numSpaces = token.trailingTrivia.numberOfSpaces
      if numSpaces > 1 {
        diagnose(.removeSpacesAfterKeyword(numSpaces - 1, token.description), on: token)
        return token.withOneTrailingSpace()
      }
    }
    return token
  }
}

/// Indicates if the token kind is an identifier
func isIdentifier(_ tokKind: TokenKind) -> Bool {
  if case .identifier(_) = tokKind {
    return true
  }
  return false
}
extension Diagnostic.Message {
  static func removeSpacesAfterKeyword(_ count: Int, _ keyWord: String) -> Diagnostic.Message {
    let ending = count == 1 ? "" : "s"
    return Diagnostic.Message(.warning, "remove \(count) space\(ending) after '\(keyWord)'")
  }
}

extension TokenKind {
  
  // Indicates if the token kind is a keyword.
  var isTypeKeyword: Bool {
    switch self {
    case .associatedtypeKeyword:
      return true
    case .classKeyword:
      return true
    case .enumKeyword:
      return true
    case .extensionKeyword:
      return true
    case .funcKeyword:
      return true
    case .importKeyword:
      return true
    case .initKeyword:
      return true
    case .inoutKeyword:
      return true
    case .letKeyword:
      return true
    case .operatorKeyword:
      return true
    case .precedencegroupKeyword:
      return true
    case .protocolKeyword:
      return true
    case .structKeyword:
      return true
    case .subscriptKeyword:
      return true
    case .typealiasKeyword:
      return true
    case .varKeyword:
      return true
    case .fileprivateKeyword:
      return true
    case .internalKeyword:
      return true
    case .privateKeyword:
      return true
    case .publicKeyword:
      return true
    case .staticKeyword:
      return true
    case .deferKeyword:
      return true
    case .ifKeyword:
      return true
    case .guardKeyword:
      return true
    case .doKeyword:
      return true
    case .repeatKeyword:
      return true
    case .elseKeyword:
      return true
    case .forKeyword:
      return true
    case .inKeyword:
      return true
    case .whileKeyword:
      return true
    case .returnKeyword:
      return true
    case .breakKeyword:
      return true
    case .continueKeyword:
      return true
    case .fallthroughKeyword:
      return true
    case .switchKeyword:
      return true
    case .caseKeyword:
      return true
    case .defaultKeyword:
      return true
    case .whereKeyword:
      return true
    case .catchKeyword:
      return true
    case .asKeyword:
      return true
    case .anyKeyword:
      return true
    case .falseKeyword:
      return true
    case .isKeyword:
      return true
    case .nilKeyword:
      return true
    case .rethrowsKeyword:
      return true
    case .superKeyword:
      return true
    case .selfKeyword:
      return true
    case .capitalSelfKeyword:
      return true
    case .throwKeyword:
      return true
    case .trueKeyword:
      return true
    case .tryKeyword:
      return true
    case .throwsKeyword:
      return true
    case .__file__Keyword:
      return true
    case .__line__Keyword:
      return true
    case .__column__Keyword:
      return true
    case .__function__Keyword:
      return true
    case .__dso_handle__Keyword:
      return true
    case .wildcardKeyword:
      return true
    case .poundAvailableKeyword:
      return true
    case .poundEndifKeyword:
      return true
    case .poundElseKeyword:
      return true
    case .poundElseifKeyword:
      return true
    case .poundIfKeyword:
      return true
    case .poundSourceLocationKeyword:
      return true
    case .poundFileKeyword:
      return true
    case .poundLineKeyword:
      return true
    case .poundColumnKeyword:
      return true
    case .poundDsohandleKeyword:
      return true
    case .poundFunctionKeyword:
      return true
    case .poundSelectorKeyword:
      return true
    case .poundKeyPathKeyword:
      return true
    case .poundColorLiteralKeyword:
      return true
    case .poundFileLiteralKeyword:
      return true
    case .poundImageLiteralKeyword:
      return true
    case .contextualKeyword(_):
      return true
    default:
      return false
    }
  }
}
