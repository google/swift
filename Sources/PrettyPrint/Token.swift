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

import Configuration
import Core
import SwiftSyntax

enum BreakStyle {
  /// A consistent break indicates that the break will always be finalized as a newline
  /// if wrapping occurs.
  case consistent

  /// Inconsistent breaks will only be expressed as a newline if they're required to be wrapped as
  /// their addition to the line would go past the line length limit.
  case inconsistent
}

enum Token {
  case comment(Comment, hasTrailingSpace: Bool)
  case newlines(Int)
  case `break`(size: Int, offset: Int)
  case open(BreakStyle, Int)
  case close
  case syntax(TokenSyntax)

  static let newline = Token.newlines(1)
  static let open = Token.open(.inconsistent, 0)

  static let `break` = Token.break(size: 1, offset: 0)
  static func `break`(offset: Int) -> Token {
    return Token.break(size: 1, offset: offset)
  }
  static func `break`(size: Int) -> Token {
    return Token.break(size: size, offset: 0)
  }
}
