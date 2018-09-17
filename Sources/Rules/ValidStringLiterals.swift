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

/// Enforces restrictions on unicode escape sequences/characters in string literals.
///
/// String literals will not mix unicode escape sequences with non-ASCII characters, and will
/// not consist of a single un-escaped Unicode control character, combining character, or variant
/// selector.
///
/// Lint: If a string consists of only Unicode control characters, combining characters, or variant
///       selectors, a lint error is raised.
///       If a string mixes non-ASCII characters and Unicode escape sequences, a lint error is
///       raised.
/// Format: String literals consisting of only Unicode modifiers will be replaced with the
///         equivalent unicode escape sequences.
///         String literals which mix non-ASCII characters and Unicode escape sequences will have
///         their unicode escape sequences replaced with the corresponding Unicode character.
///
/// - SeeAlso: https://google.github.io/swift#invisible-characters-and-modifiers
///            https://google.github.io/swift#string-literals
public final class ValidStringLiterals: SyntaxFormatRule {

}
