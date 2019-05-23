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

import Foundation
import SwiftFormatConfiguration
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

  /// An object that converts `AbsolutePosition` values to `SourceLocation` values.
  public let sourceLocationConverter: SourceLocationConverter

  /// Creates a new Context with the provided configuration, diagnostic engine, and file URL.
  public init(
    configuration: Configuration,
    diagnosticEngine: DiagnosticEngine?,
    fileURL: URL,
    sourceFileSyntax: SourceFileSyntax
  ) {
    self.configuration = configuration
    self.diagnosticEngine = diagnosticEngine
    self.fileURL = fileURL
    self.importsXCTest = false
    self.didSetImportsXCTest = false
    self.sourceLocationConverter =
      SourceLocationConverter(file: fileURL.path, tree: sourceFileSyntax)
  }

  /// Creates a new Context with the provided configuration, diagnostic engine, and source text.
  public init(
    configuration: Configuration,
    diagnosticEngine: DiagnosticEngine?,
    fileURL: URL,
    sourceText: String
  ) {
    self.configuration = configuration
    self.diagnosticEngine = diagnosticEngine
    self.fileURL = fileURL
    self.importsXCTest = false
    self.didSetImportsXCTest = false
    self.sourceLocationConverter = SourceLocationConverter(file: fileURL.path, source: sourceText)
  }
}
