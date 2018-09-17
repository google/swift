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

extension TokenKind {
  /// Whether this token is the 'left' token of a pair of balanced
  /// delimiters (paren, angle bracket, square bracket.)
  var isLeftBalancedDelimiter: Bool {
    switch self {
    case .leftParen, .leftSquareBracket, .leftAngle:
      return true
    default:
      return false
    }
  }

  /// Whether this token is the 'right' token of a pair of balanced
  /// delimiters (paren, angle bracket, square bracket.)
  var isRightBalancedDelimiter: Bool {
    switch self {
    case .rightParen, .rightSquareBracket, .rightAngle:
      return true
    default:
      return false
    }
  }
}
