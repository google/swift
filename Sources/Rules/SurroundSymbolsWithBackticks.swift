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

/// Symbols should be surrounded with backticks in comments.
///
/// Note that we do not have semantic analysis and symbols are not matched outside of a limited set
/// of global symbols (such as `String`) and symbols declared in the file.
///
/// Lint: Using a symbol without surrounding backticks yields a lint error.
///
/// Format: Detected symbols are surrounded with backticks if not already surrounded.
///
/// Configuration: symbolWhitelist, symbolBlacklist.
///
/// - SeeAlso: https://google.github.io/swift#apples-markup-format
public final class SurroundSymbolsWithBackticks: SyntaxFormatRule {

}
