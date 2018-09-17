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

/// Trailing closures are preferred wherever possible, except if a function has multiple closure
/// arguments.
///
/// Lint: TODO(abl): Figure out a consistent set of linting rules for this. The problem is it's not
///                  always safe to recommend foo({ $0 }) -> foo { $0 }, in the case where foo has
///                  default arguments after the closure parameter.
///
/// Format: TODO(abl): Figure out a consistent set of linting rules for formatting (see above)
///
/// - SeeAlso: https://google.github.io/swift#trailing-closures
public final class UseTrailingClosure: SyntaxFormatRule {

}
