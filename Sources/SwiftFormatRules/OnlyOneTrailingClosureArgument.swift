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

/// Function calls should never mix normal closure arguments and trailing closures.
///
/// Lint: If a function call with a trailing closure also contains a non-trailing closure argument,
///       a lint error is raised.
///
/// - SeeAlso: https://google.github.io/swift#trailing-closures
public struct OnlyOneTrailingClosureArgument: SyntaxLintRule {

  public let context: Context

  public init(context: Context) {
    self.context = context
  }

  public func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
    guard (node.argumentList.contains { $0.expression is ClosureExprSyntax }) else { return .skipChildren }
    guard node.trailingClosure != nil else { return .skipChildren }
    diagnose(.removeTrailingClosure, on: node)
    return .skipChildren
  }
}

extension Diagnostic.Message {
  static let removeTrailingClosure =
    Diagnostic.Message(.warning,
                      "function call shouldn't have both closure arguments and a trailing closure")
}
