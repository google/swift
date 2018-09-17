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

import Configuration
import SwiftSyntax

/// A linting rule that does not parse the file, but instead runs analyses over the raw text of
/// the file.
open class FileRule: Rule {
  /// The context in which this rule in run.
  public let context: Context

  /// Creates a new FileRule executing in the provided context.
  public required init(context: Context) {
    self.context = context
  }
}
