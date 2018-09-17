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

/// Source files are encoded in UTF-8.
///
/// Lint: Files encoded in anything but UTF-8 will yield a lint error.
///
/// Format: If the given file is not UTF-8, it will be transcoded to UTF-8.
///
/// SeeAlso: https://google.github.io/swift#file-encoding
public final class UseOnlyUTF8: FileRule {

}
