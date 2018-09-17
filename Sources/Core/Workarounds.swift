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

// This file contains workarounds for bugs in SwiftSyntax (or the compiler itself) and should
// hopefully be temporary.

import SwiftSyntax

extension FunctionParameterSyntax {

  /// The optional trailing comma that follows a function parameter, implementing a workaround for a
  /// bug in the Swift 4.2 compiler (and, at the time of this writing, also in master).
  ///
  /// If a function parameter has either an ellipsis or default argument expression, the trailing
  /// comma (if present) is located correctly in the layout at index 7. However, if neither an
  /// ellipsis or default argument is present, the comma token will be incorrectly located at index
  /// 5 (where the ellipsis would normally be). This workaround checks the expected location first,
  /// then falls back to the incorrect location to find a comma before giving up. (rdar://43690589)
  public var trailingCommaWorkaround: TokenSyntax? {
    if let comma = trailingComma { return comma }
    if let comma = ellipsis, comma.tokenKind == .comma { return comma }
    return nil
  }
}
