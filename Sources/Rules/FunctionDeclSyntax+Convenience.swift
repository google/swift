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

extension FunctionDeclSyntax {
  /// Constructs a name for a function that includes parameter labels, i.e. `foo(_:bar:)`.
  var fullDeclName: String {
    let params = signature.input.parameterList.map { param in
      "\(param.firstName?.text ?? "_"):"
    }
    return "\(identifier.text)(\(params.joined()))"
  }
}
