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

/// Playground literals (e.g. `#colorLiteral`) are forbidden.
///
/// For the case of `#colorLiteral`, if `import AppKit` is present, `NSColor` will be used.
/// If `import UIKit` is present, `UIColor` will be used.
/// If neither `import` is present, `resolveAmbiguousColor` will be used to determine behavior.
///
/// Lint: Using a playground literal will yield a lint error.
///
/// Format: The playground literal will be replaced with the matching class; e.g.
///         `#colorLiteral(...)` becomes `UIColor(...)`
///
/// Configuration: resolveAmbiguousColor
///
/// - SeeAlso: https://google.github.io/swift#playground-literals
public final class NoPlaygroundLiterals: SyntaxFormatRule {

}
