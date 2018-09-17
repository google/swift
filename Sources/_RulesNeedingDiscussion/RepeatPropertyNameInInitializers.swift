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

/// Initializer arguments that are assigned to a property must have the same name as that property.
///
/// TODO(abl): This requires semantic analysis as properties might be from superclass types.
///            In general, this rule appears to be error-prone.
///
/// - SeeAlso: https://google.github.io/swift#initializers
public final class RepeatPropertyNameInInitializers {

}
