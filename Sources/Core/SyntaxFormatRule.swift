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

import SwiftSyntax

/// A rule that both formats and lints a given file.
open class SyntaxFormatRule: SyntaxRewriter, Rule {
  /// The context in which the rule is executed.
  public let context: Context

  /// Creates a new SyntaxFormatRule in the given context.
  public required init(context: Context) {
    self.context = context
  }
}
