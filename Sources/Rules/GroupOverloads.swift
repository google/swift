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

/// Overloads, subscripts, and initializers should be grouped if they appear in the same scope.
///
/// Lint: If an overload appears ungrouped with another member of the overload set, a lint error
///       will be raised.
///
/// Format: Overloaded declarations will be grouped together.
///
/// - SeeAlso: https://google.github.io/swift#overloaded-declarations
public final class GroupOverloads: SyntaxFormatRule {

}
