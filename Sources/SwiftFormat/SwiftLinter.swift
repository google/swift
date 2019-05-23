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
import SwiftFormatCore
import SwiftFormatPrettyPrint
import SwiftFormatWhitespaceLinter
import SwiftSyntax

/// Diagnoses and reports problems in Swift source code or syntax trees according to the Swift style
/// guidelines.
public final class SwiftLinter {

  /// The configuration settings that control the linter's behavior.
  public let configuration: Configuration

  /// A diagnostic engine to which lint findings will be reported.
  public let diagnosticEngine: DiagnosticEngine

  /// Advanced options that are useful when debugging the linter's behavior but are not meant for
  /// general use.
  public var debugOptions: DebugOptions = []

  /// Creates a new Swift code linter with the given configuration.
  ///
  /// - Parameters:
  ///   - configuration: The configuration settings that control the linter's behavior.
  ///   - diagnosticEngine: The diagnostic engine to which lint findings will be reported.
  public init(configuration: Configuration, diagnosticEngine: DiagnosticEngine) {
    self.configuration = configuration
    self.diagnosticEngine = diagnosticEngine
  }

  /// Lints the Swift code at the given file URL.
  ///
  /// - Parameters url: The URL of the file containing the code to format.
  /// - Throws: If an unrecoverable error occurs when formatting the code.
  public func lint(contentsOf url: URL) throws {
    guard FileManager.default.isReadableFile(atPath: url.path) else {
      throw SwiftFormatError.fileNotReadable
    }
    var isDir: ObjCBool = false
    if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir), isDir.boolValue {
      throw SwiftFormatError.isDirectory
    }
    let sourceFile = try SyntaxParser.parse(url)
    try lint(syntax: sourceFile, assumingFileURL: url)
  }

  /// Lints the given Swift syntax tree.
  ///
  /// - Parameters:
  ///   - syntax: The Swift syntax tree to be converted to be linted.
  ///   - url: A file URL denoting the filename/path that should be assumed for this syntax tree.
  ///   - outputStream: A value conforming to `TextOutputStream` to which the formatted output will
  ///     be written.
  /// - Throws: If an unrecoverable error occurs when formatting the code.
  public func lint(syntax: SourceFileSyntax, assumingFileURL url: URL) throws {
    let context = Context(
      configuration: configuration, diagnosticEngine: diagnosticEngine, fileURL: url,
      sourceFileSyntax: syntax)
    var pipeline = LintPipeline(context: context)
    syntax.walk(&pipeline)

    // Perform whitespace linting by comparing the input source text with the output of the
    // pretty-printer.
    let printer = PrettyPrinter(
      context: context,
      node: syntax,
      printTokenStream: debugOptions.contains(.dumpTokenStream))
    let formatted = printer.prettyPrint()
    let ws = WhitespaceLinter(user: syntax.description, formatted: formatted, context: context)
    ws.lint()
  }

  // TODO: Add an overload of `lint` that takes the source text directly.
}
