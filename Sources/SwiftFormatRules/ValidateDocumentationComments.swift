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

import Foundation
import SwiftFormatCore
import SwiftSyntax

/// Documentation comments must be complete and valid.
///
/// "Command + Option + /" in Xcode produces a minimal valid documentation comment.
///
/// Lint: Documentation comments that are incomplete (e.g. missing parameter documentation) or
///       invalid (uses `Parameters` when there is only one parameter) will yield a lint error.
///
/// - SeeAlso: https://google.github.io/swift#parameter-returns-and-throws-tags
public struct ValidateDocumentationComments: SyntaxLintRule {
  public let context: Context

  public init(context: Context) {
    self.context = context
  }

  public func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
    guard let declComment = node.docComment else { return .skipChildren }
    guard let commentInfo = node.docCommentInfo else { return .skipChildren }
    guard let params = commentInfo.parameters else { return .skipChildren }

    // If a single sentence summary is the only documentation, parameter(s) and
    // returns tags may be ommitted.
    if commentInfo.oneSentenceSummary != nil &&
      commentInfo.commentParagraphs!.isEmpty &&
      params.isEmpty &&
      commentInfo.returnsDescription == nil {
      return .skipChildren
    }

    // Indicates if the documentation uses 'Parameters' as description of the
    // documented parameters.
    let hasPluralDesc = declComment.components(separatedBy: .newlines)
      .contains { $0.trimmingCharacters(in: .whitespaces).starts(with: "- Parameters") }

    validateReturn(node, returnDesc: commentInfo.returnsDescription)
    let funcParameters = funcParametersIdentifiers(in: node.signature.input.parameterList)

    // If the documentation of the parameters is wrong 'docCommentInfo' won't
    // parse the parameters correctly. First the documentation has to be fix
    // in order to validate the other conditions.
    if hasPluralDesc && funcParameters.count == 1 {
      diagnose(.useSingularParameter, on: node)
      return .skipChildren
    }
    else if !hasPluralDesc && funcParameters.count > 1 {
      diagnose(.usePluralParameters, on: node)
      return .skipChildren
    }

    // Ensures that the parameters of the documantation and the function signature
    // are the same.
    if (params.count != funcParameters.count) ||
      !parametersAreEqual(params: params, funcParam: funcParameters) {
      diagnose(.parametersDontMatch(funcName: node.identifier.text), on: node)
    }

    return .skipChildren
  }

  /// Ensures the function has a return documentation if it actually returns
  /// a value.
  func validateReturn(_ node: FunctionDeclSyntax, returnDesc: String?) {
    if node.signature.output == nil && returnDesc != nil {
      diagnose(.removeReturnComment(funcName: node.identifier.text), on: node)
    }
    else if node.signature.output != nil && returnDesc == nil {
      diagnose(.documentReturnValue(funcName: node.identifier.text), on: node)
    }
  }
}

/// Iterates through every parameter of paramList and returns a list of the
/// paramters identifiers.
func funcParametersIdentifiers(in paramList: FunctionParameterListSyntax) -> [String] {
  var funcParameters = [String]()
  for parameter in paramList
  {
    guard let parameterIdentifier = parameter.firstName else { continue }
    funcParameters.append(parameterIdentifier.text)
  }
  return funcParameters
}

/// Indicates if the parameters name from the documentation and the parameters
/// from the declaration are the same.
func parametersAreEqual(params: [ParseComment.Parameter], funcParam: [String]) -> Bool {
  for index in 0..<params.count {
    if params[index].name != funcParam[index] {
      return false
    }
  }
  return true
}

extension Diagnostic.Message {
  static func documentReturnValue(funcName: String) -> Diagnostic.Message {
    return Diagnostic.Message(.warning, "document the return value of \(funcName)")
  }

  static func removeReturnComment(funcName: String) -> Diagnostic.Message {
    return Diagnostic.Message(
      .warning,
      "remove the return comment of \(funcName), it doesn't return a value"
    )
  }

  static func parametersDontMatch(funcName: String) -> Diagnostic.Message {
    return Diagnostic.Message(
      .warning,
      "the parameters of \(funcName) don't match the parameters in its documentation"
    )
  }

  static let useSingularParameter =
    Diagnostic.Message(
      .warning,
      "replace the plural form of 'Parameters' with a singular inline form of the 'Parameter' tag"
    )

  static let usePluralParameters =
    Diagnostic.Message(
      .warning,
      "replace the singular inline form of 'Parameter' tag with a plural 'Parameters' tag " +
        "and group each parameter as a nested list"
     )
}
