import Configuration
import Core
import Foundation
import Rules
import PrettyPrint
import SwiftSyntax

/// Runs the linting pipeline over the provided source file.
///
/// If there were any lint diagnostics emitted, this function returns a non-zero exit code.
/// - Parameter path: The absolute path to the source file to be linted.
/// - Returns: Zero if there were no lint errors, otherwise a non-zero number.
public func lintMain(path: String) -> Int {
  let url = URL(fileURLWithPath: path)
  let engine = DiagnosticEngine()
  let consumer = PrintingDiagnosticConsumer()
  engine.addConsumer(consumer)

  let context = Context(
    configuration: Configuration(),
    diagnosticEngine: engine,
    fileURL: url
  )

  let pipeline = LintPipeline(context: context)
  populate(pipeline)

  do {
    let file = try SyntaxTreeParser.parse(url)

    // Important! We need to cast this to Syntax to avoid going directly into the specialized
    // version of visit(_: SourceFileSyntax), which will not run the pipeline properly.
    pipeline.visit(file as Syntax)
  } catch {
    fatalError("\(error)")
  }
  return engine.diagnostics.isEmpty ? 0 : 1
}

/// Runs the formatting pipeline over the provided source file.
///
/// - Parameter path: The absolute path to the source file to be linted.
/// - Returns: Zero if there were no lint errors, otherwise a non-zero number.
public func formatMain(path: String, isDebugMode: Bool) -> Int {
  let url = URL(fileURLWithPath: path)

  let config = Configuration()
  config.lineLength = 80

  let context = Context(
    configuration: config,
    diagnosticEngine: nil,
    fileURL: url
  )

  let pipeline = FormatPipeline(context: context)
  populate(pipeline)
  do {
    let file = try SyntaxTreeParser.parse(url)

    // Important! We need to cast this to Syntax to avoid going directly into the specialized
    // version of visit(_: SourceFileSyntax), which will not run the pipeline properly.
    let formatted = pipeline.visit(file as Syntax)
    let printer = PrettyPrinter(
      configuration: context.configuration,
      node: formatted,
      isDebugMode: isDebugMode
    )
    print(printer.prettyPrint(), terminator: "")
//    let output = url.deletingPathExtension().appendingPathExtension("formatted.swift")
//    try formatted.description.write(to: output, atomically: true, encoding: .utf8)
  } catch {
    fatalError("\(error)")
  }
  return 0
}
