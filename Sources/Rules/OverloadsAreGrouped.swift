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

/// Multiple overloads with the same base name must be grouped together, appearing seqeuntially.
///
/// Initializers and subscripts are considered to have the same base name.
///
/// Lint: Overloads that do not appear sequentially will yield lint errors.
///
/// Format: Overloads will be moved so that they are sequential; they will all appear after the
///         first matching overload in the file.
///
/// - SeeAlso: https://google.github.io/swift#overloaded-declarations
public final class OverloadsAreGrouped: SyntaxFormatRule {

}
