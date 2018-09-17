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

/// Redundant labels are forbidden in case patterns.
///
/// In practice, *all* case pattern labels should be redundant.
///
/// Lint: Using a label in a case statement yields a lint error unless the label does not match the
///       binding identifier.
///
/// Format: Redundant labels in case patterns are removed.
///
/// - SeeAlso: https://google.github.io/swift#pattern-matching
public final class NoLabelsInCasePatterns: SyntaxFormatRule {
  public override func visit(_ node: SwitchCaseLabelSyntax) -> Syntax {

    var newCaseItems: [CaseItemSyntax] = []
    for item in node.caseItems {
      guard let expPat = item.pattern as? ExpressionPatternSyntax else {
        newCaseItems.append(item)
        continue
      }
      guard let funcCall = expPat.expression as? FunctionCallExprSyntax else {
        newCaseItems.append(item)
        continue
      }

      // Search function call argument list for violations
      var newArgs: [FunctionCallArgumentSyntax] = []
      for argument in funcCall.argumentList {
        guard let label = argument.label else {
          newArgs.append(argument)
          continue
        }
        guard let unresolvedPat = argument.expression as? UnresolvedPatternExprSyntax,
          let valueBinding = unresolvedPat.pattern as? ValueBindingPatternSyntax else {
          newArgs.append(argument)
          continue
        }

        // Remove label if it's the same as the value identifier
        let name = valueBinding.valuePattern.description.trimmingCharacters(in: .whitespaces)
        guard name == label.text else {
          newArgs.append(argument)
          continue
        }
        diagnose(.removeRedundantLabel(name: name), on: label)
        newArgs.append(argument.withLabel(nil).withColon(nil))
      }
      
      let newArgList = SyntaxFactory.makeFunctionCallArgumentList(newArgs)
      let newFuncCall = funcCall.withArgumentList(newArgList)
      let newExpPat = expPat.withExpression(newFuncCall)
      let newItem = item.withPattern(newExpPat)
      newCaseItems.append(newItem)
    }
    let newCaseItemList = SyntaxFactory.makeCaseItemList(newCaseItems)
    return node.withCaseItems(newCaseItemList)
  }
}

extension Diagnostic.Message {
  static func removeRedundantLabel(name: String) -> Diagnostic.Message {
    return .init(.warning, "remove \(name) label from case argument")
  }
}
