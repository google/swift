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

/// Enforces line length limits.
///
/// Lint: If a line exceeds the maximum line length, a lint error is raised.
///
/// Format: Overloaded declarations will be grouped together.
///
/// - SeeAlso: https://google.github.io/swift#column-limit
public final class LineLengthLimit: SyntaxLintRule {

}
