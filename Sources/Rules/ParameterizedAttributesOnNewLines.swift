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

/// Parameterized attributes must be written on individual lines, ordered lexicographically.
///
/// Lint: Parameterized attributes not on an individual line will yield a lint error.
///       Parameterized attributes not in lexicographic order will yield a lint error.
///
/// Format: Parameterized attributes will be placed on individual lines in lexicographic order.
///
/// - SeeAlso: https://google.github.io/swift#attributes
public final class ParameterizedAttributesOnNewLines: SyntaxFormatRule {

}
