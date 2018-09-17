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
import Foundation
import SwiftSyntax

/// Context contains the bits that each formatter and linter will need access to.
///
/// Specifically, it is the container for the shared configuration, diagnostic engine, and URL of
/// the current file.
public class Context {
  /// The configuration for this run of the pipeline, provided by a configuration JSON file.
  public let configuration: Configuration

  /// The engine in which to emit diagnostics, if running in Lint mode.
  public let diagnosticEngine: DiagnosticEngine?

  /// The URL of the file being linted or formatted.
  public let fileURL: URL
  
  /// Indicates whether the file imports XCTest, and is test code
  public var importsXCTest: Bool
  
  /// Indicates whether the visitor has already determined a value for importsXCTest
  public var didSetImportsXCTest: Bool

  /// Creates a new Context with the provided configuration, diagnostic engine, and file URL.
  public init(configuration: Configuration, diagnosticEngine: DiagnosticEngine?, fileURL: URL) {
    self.configuration = configuration
    self.diagnosticEngine = diagnosticEngine
    self.fileURL = fileURL
    self.importsXCTest = false
    self.didSetImportsXCTest = false
  }
}
