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

import SwiftSyntax

extension Diagnostic.Message {
    /// Prepends the name of a rule to this diagnostic message.
    /// - parameter rule: The rule whose name will be prepended to the diagnostic.
    /// - returns: A new `Diagnostic.Message` with the name of the provided rule prepended.
    public func withRule(_ rule: Rule) -> Diagnostic.Message {
        return .init(severity, "[\(rule.ruleName)]: \(text)")
    }
}
