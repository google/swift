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

/// Every element bound in a `case` must have its own `let`.
///
/// e.g. `case let .label(foo, bar)` is forbidden.
///
/// Lint: `case let ...` will yield a lint error.
///
/// Format: The `let` will be distributed across each element.
///         TODO(abl): This is not a neutral format operation.
///
/// - SeeAlso: https://google.github.io/swift#pattern-matching
public final class UseLetInEveryBoundCaseVariable: SyntaxLintRule {

  public override func visit(_ node: SwitchCaseLabelSyntax) {
    for item in node.caseItems {
      guard item.pattern is ValueBindingPatternSyntax else { continue }
      diagnose(.useLetInBoundCaseVariables, on: node)
    }
  }
}

extension Diagnostic.Message {
  static let useLetInBoundCaseVariables = Diagnostic.Message(.warning,
                                           "distribute 'let' to each bound case variable")
}
