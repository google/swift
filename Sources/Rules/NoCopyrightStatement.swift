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

/// Swift source files do not contain a copyright statement.
///
/// Lint: If the first comment in a source file contains a copyright statement, a lint error will
///       be raised.
///
/// Format: Copyright statements in source files will be removed.
///
/// - SeeAlso: https://google.github.io/swift#copyright-statement
public final class NoCopyrightStatement: SyntaxFormatRule {

}
