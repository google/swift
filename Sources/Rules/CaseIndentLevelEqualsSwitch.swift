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

/// Each `case` of a `switch` statement must be indented the same as the `switch` keyword.
///
/// Lint: If a case's indentation is over- or under-indented relative to the `switch` keyword, a
///       lint error is raised.
///
/// Format: Cases will be re-indented to match their accompanying `switch` keyword.
///
/// - SeeAlso: https://google.github.io/swift#switch-statements
public final class CaseIndentLevelEqualsSwitch: SyntaxFormatRule {
  public override func visit(_ node: SwitchStmtSyntax) -> StmtSyntax {
    var cases = [Syntax]()
    guard let switchIndentation = node.leadingTrivia?.numberOfSpaces else { return node }
    var spacesDif: Int
    var isInvalid = false

    // Iterates through the switch stamentent to ensure the number of spaces
    // in the indentation of each case is the same as the switch keyword.
    for caseExp in node.cases {
      guard let caseTrivia = caseExp.leadingTrivia else { continue }

      if caseTrivia.numberOfSpaces != switchIndentation {
        spacesDif = switchIndentation - caseTrivia.numberOfSpaces
        diagnose(
          .adjustIndentationSpaces(
          count: spacesDif,
          caseText: caseExp.description),
          on: node
        )

        let newCase = replaceTrivia(on: caseExp, token: caseExp.firstToken, leadingTrivia:
                Trivia.newlines(caseTrivia.numberOfNewlines).appending(.spaces(switchIndentation)))
        isInvalid = true
        cases.append(newCase)
      }
      else {
        cases.append(caseExp)
      }
    }
    return isInvalid ? node.withCases(SyntaxFactory.makeSwitchCaseList(cases)) : node
  }
}

extension Diagnostic.Message {
  static func adjustIndentationSpaces(count: Int, caseText: String) -> Diagnostic.Message {
    let adjustSpaces = count < 0 ? "remove" : "add"
    let ending = abs(count) == 1 ? "" : "s"
    return Diagnostic.Message(
      .warning,
      "\(adjustSpaces) \(abs(count)) space\(ending) as indentation to the case \(caseText)"
    )
  }
}
