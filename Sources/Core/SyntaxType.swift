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

/// SyntaxType is a small wrapper around a metatype of the Syntax protocol that allows for easy
/// hashing and ==.
struct SyntaxType: Hashable {
  let type: Syntax.Type

  static func ==(lhs: SyntaxType, rhs: SyntaxType) -> Bool {
    return ObjectIdentifier(lhs.type) == ObjectIdentifier(rhs.type)
  }

  var hashValue: Int {
    return ObjectIdentifier(type).hashValue
  }
}
