import Configuration
import Core
import SwiftSyntax
import XCTest

/// DiagnosingTestCase is an XCTestCase subclass meant to inject diagnostic-specific testing
/// routines into specific formatting test cases.
public class DiagnosingTestCase: XCTestCase {
  /// The context each test runs in.
  public private(set) var context: Context?

  /// A helper that will keep track of the number of times a specific diagnostic was emitted.
  private var consumer = DiagnosticTrackingConsumer()

  private class DiagnosticTrackingConsumer: DiagnosticConsumer {
    var registeredDiagnostics = [String]()
    func handle(_ diagnostic: Diagnostic) {
      registeredDiagnostics.append(diagnostic.message.text)
      for note in diagnostic.notes {
        registeredDiagnostics.append(note.message.text)
      }
    }
    func finalize() {}
  }

  /// Creates a new Context and DiagnosticTrackingConsumer for this test case.
  public override func setUp() {
    context = Context(
      configuration: Configuration(),
      diagnosticEngine: DiagnosticEngine(),
      fileURL: URL(fileURLWithPath: "/tmp/test.swift")
    )
    consumer = DiagnosticTrackingConsumer()
    context?.diagnosticEngine?.addConsumer(consumer)
  }

  public override func tearDown() {
    // This will emit a test failure if a diagnostic is thrown but we don't explicitly call
    // XCTAssertDiagnosed for it. I (hbh) am personally on the fence about whether to include
    // this test.
    #if false
    for (diag, count) in consumer.registeredDiagnostics where count > 0 {
      XCTFail("unexpected diagnostic '\(diag)' thrown \(count) time\(count == 1 ? "" : "s")")
    }
    #endif
  }

  /// Performs a lint using the provided linter rule on the provided input.
  ///
  /// - Parameters:
  ///   - type: The metatype of the lint rule you wish to perform.
  ///   - input: The input code.
  ///   - file: The file the test resides in (defaults to the current caller's file)
  ///   - line:  The line the test resides in (defaults to the current caller's line)
  func performLint(
    _ type: SyntaxLintRule.Type,
    input: String,
    file: StaticString = #file,
    line: UInt = #line) {
    do {
      let syntax = try SyntaxTreeParser.parse(input)
      let linter = type.init(context: context!)
      linter.visit(syntax)
    } catch {
      XCTFail("\(error)", file: file, line: line)
    }
  }

  /// Asserts that the result of applying a formatter to the provided input code yields the output.
  ///
  /// This method should be called by each test of each rule.
  ///
  /// - Parameters:
  ///   - formatType: The metatype of the format rule you wish to apply.
  ///   - input: The unformatted input code.
  ///   - expected: The expected result of formatting the input code.
  ///   - file: The file the test resides in (defaults to the current caller's file)
  ///   - line:  The line the test resides in (defaults to the current caller's line)
  func XCTAssertFormatting(
    _ formatType: SyntaxFormatRule.Type,
    input: String,
    expected: String,
    file: StaticString = #file,
    line: UInt = #line
  ) {
    do {
      let syntax = try SyntaxTreeParser.parse(input)
      let formatter = formatType.init(context: context!)
      let result = formatter.visit(syntax)
      XCTAssertDiff(result: result.description, expected: expected, file: file, line: line)
    } catch {
      XCTFail("\(error)", file: file, line: line)
    }
  }

  /// Asserts that the two expressions have the same value, and provides a detailed
  /// message in the case there is a difference between both expression.
  ///
  /// - Parameters:
  ///   - result: The result of formatting the input code.
  ///   - expected: The expected result of formatting the input code.
  ///   - file: The file the test resides in (defaults to the current caller's file)
  ///   - line:  The line the test resides in (defaults to the current caller's line)
  func XCTAssertDiff(result: String, expected: String, file: StaticString, line: UInt) {
    let resultLines = result.components(separatedBy: .newlines)
    let expectedLines = expected.components(separatedBy: .newlines)
    let minCount = min(resultLines.count, expectedLines.count)
    let maxCount = max(resultLines.count, expectedLines.count)

    var index = 0
    // Iterates through both expressions while there are no differences.
    while index < minCount && resultLines[index] == expectedLines[index] { index += 1 }

    // If the index is not the same as the number of lines, it's because a
    // difference was found.
    if maxCount != index {
      let message = """
                    Actual and expected have a difference on line of code \(index + 1)
                    Actual line of code: "\(resultLines[index])"
                    Expected line of code: "\(expectedLines[index])"
                    ACTUAL:
                    ("\(result)")
                    EXPECTED:
                    ("\(expected)")
                    """
      XCTFail(message, file: file, line: line)
    }
  }

  /// Asserts that a specific diagnostic message was not emitted.
  ///
  /// - Parameters:
  ///   - message: The diagnostic message to check for.
  ///   - file: The file the test resides in (defaults to the current caller's file)
  ///   - line:  The line the test resides in (defaults to the current caller's line)
  func XCTAssertNotDiagnosed(
    _ message: Diagnostic.Message,
    file: StaticString = #file,
    line: UInt = #line
  ) {
    // This has to be a linear search, because the tests are going to check for the version
    // of the diagnostic that is not annotated with '[NameOfRule]:'.
    let hadDiag = consumer.registeredDiagnostics.contains {
      $0.contains(message.text)
    }

    if hadDiag {
      XCTFail("diagnostic '\(message.text)' should not have been raised", file: file, line: line)
    }
  }

  /// Asserts that a specific diagnostic message was emitted.
  ///
  /// - Parameters:
  ///   - message: The diagnostic message to check for.
  ///   - file: The file the test resides in (defaults to the current caller's file)
  ///   - line:  The line the test resides in (defaults to the current caller's line)
  func XCTAssertDiagnosed(
    _ message: Diagnostic.Message,
    file: StaticString = #file,
    line: UInt = #line
  ) {
    // This has to be a linear search, because the tests are going to check for the version
    // of the diagnostic that is not annotated with '[NameOfRule]:'.
    let maybeIdx = consumer.registeredDiagnostics.index {
      $0.contains(message.text)
    }

    guard let idx = maybeIdx else {
      XCTFail("diagnostic '\(message.text)' not raised", file: file, line: line)
      return
    }

    consumer.registeredDiagnostics.remove(at: idx)
  }
}
