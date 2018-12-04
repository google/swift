//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2018 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import SwiftFormatConfiguration
import SwiftFormatCore
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
  case syntax(TokenSyntax)
  case open(BreakStyle, Int)
  case close
  case `break`(size: Int, offset: Int)
  case space(size: Int)
  case newlines(Int, offset: Int)
  case comment(Comment)
  case reset
  case verbatim(Verbatim)

  // Convenience overloads for the enum types
  static let open = Token.open(.inconsistent, 0)

  static let newline = Token.newlines(1, offset: 0)
  static func newline(offset: Int) -> Token {
    return Token.newlines(1, offset: offset)
  }

  static let space = Token.space(size: 1)

  static let `break` = Token.break(size: 1, offset: 0)
  static func `break`(offset: Int) -> Token {
    return Token.break(size: 1, offset: offset)
  }
  static func `break`(size: Int) -> Token {
    return Token.break(size: size, offset: 0)
  }

  static func verbatim(text: String) -> Token {
    return Token.verbatim(Verbatim(text: text))
  }
}
