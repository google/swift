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

import SwiftFormatConfiguration
import SwiftFormatCore
import SwiftSyntax

/// PrettyPrinter takes a Syntax node and outputs a well-formatted, re-indented reproduction of the
/// code as a String.
public class PrettyPrinter {
  private let context: Context
  private var configuration: Configuration { return context.configuration }
  private let maxLineLength: Int
  private var tokens: [Token]
  private var outputBuffer: String = ""

  /// The number of spaces remaining on the current line.
  private var spaceRemaining: Int

  /// Keep track of the token lengths.
  private var lengths = [Int]()

  /// Did the previous token create a new line? This is used to determine if a group needs to
  /// consistently break.
  private var lastBreak = false

  /// Keeps track of the base indentation level (as determined by the unclosed `.break(.open)`
  /// tokens) as a sequence of space or tab values.
  private var indentationStack: [Indent] = []

  /// Keep track of whether we are forcing breaks within a group (for consistent breaking).
  private var forceBreakStack = [false]

  /// If true, the token stream is printed to the console for debugging purposes.
  private var printTokenStream: Bool

  /// Keeps track of the line numbers of the open (and unclosed) breaks seen so far.
  private var openDelimiterBreakStack: [Int] = []

  /// Keeps track of the current line number being printed.
  private var lineNumber: Int = 0

  /// Indicates whether or not the current line being printed is a continuation line.
  private var currentLineIsContinuation = false

  /// Keeps track of the most recent number of consecutive newlines that have been printed.
  ///
  /// This value is reset to zero whenever non-newline content is printed.
  private var consecutiveNewlineCount = 0

  /// Keeps track of the most recent number of spaces that should be printed before the next text
  /// token.
  private var pendingSpaces = 0

  /// Indicates whether or not the printer is currently at the beginning of a line.
  private var isAtStartOfLine = true

  /// The kind of the last break token that was printed.
  private var lastBreakKind: BreakKind = .reset

  /// The computed indentation level, as a number of spaces, based on the state of any unclosed
  /// delimiters and whether or not the current line is a continuation line.
  private var currentIndentation: [Indent] {
    var totalIndentation = indentationStack
    if currentLineIsContinuation {
      totalIndentation.append(configuration.indentation)
    }
    return totalIndentation
  }

  /// Creates a new PrettyPrinter with the provided formatting configuration.
  ///
  /// - Parameters:
  ///   - context: The formatter context.
  ///   - node: The node to be pretty printed.
  public init(context: Context, node: Syntax, printTokenStream: Bool) {
    self.context = context
    let configuration = context.configuration
    self.tokens = node.makeTokenStream(configuration: configuration)
    self.maxLineLength = configuration.lineLength
    self.spaceRemaining = self.maxLineLength
    self.printTokenStream = printTokenStream
  }

  /// Append the given string to the output buffer.
  ///
  /// No further processing is performed on the string.
  private func writeRaw<S: StringProtocol>(_ str: S) {
    outputBuffer.append(String(str))
  }

  /// Ensures that the given number of newlines to the output stream (taking into account any
  /// pre-existing consecutive newlines).
  ///
  /// This function does some implicit collapsing of consecutive newlines to ensure that the
  /// results are consistent when breaks and explicit newlines coincide. For example, imagine a
  /// break token that fires (thus creating a single non-discretionary newline) because it is
  /// followed by a group that contains 2 discretionary newlines that were found in the user's
  /// source code at that location. In that case, the break "overlaps" with the discretionary
  /// newlines and it will write a newline before we get to the discretionaries. Thus, we have to
  /// subtract the previously written newlines during the second call so that we end up with the
  /// correct number overall.
  ///
  /// - Parameters:
  ///   - count: The number of newlines to write.
  ///   - discretionary: Indicates whether the newlines are user-entered discretionary newlines.
  ///     Discretionary newlines are always printed, after excluding any other consecutive newlines
  ///     thus far, and up through the maximum allowed number provided to the printer at
  ///     initialization time. Non-discretionary newlines are only printed if discretionary newlines
  ///     have already not been printed yet.
  private func writeNewlines(_ count: Int, discretionary: Bool) {
    // We add 1 because it takes 2 newlines to create a blank line.
    let maximumNewlines = configuration.maximumBlankLines + 1
    let numberToPrint: Int
    if count <= maximumNewlines {
      numberToPrint = count - consecutiveNewlineCount
    } else {
      numberToPrint = maximumNewlines - consecutiveNewlineCount
    }

    guard (discretionary && numberToPrint > 0) || consecutiveNewlineCount == 0 else { return }

    writeRaw(String(repeating: "\n", count: numberToPrint))
    lineNumber += numberToPrint
    isAtStartOfLine = true
    consecutiveNewlineCount += numberToPrint
    pendingSpaces = 0
  }

  /// Request that the given number of spaces be printed out before the next text token.
  ///
  /// Spaces are printed only when the next text token is printed in order to prevent us from
  /// printing lines that are only whitespace or have trailing whitespace.
  private func enqueueSpaces(_ count: Int) {
    pendingSpaces += count
    spaceRemaining -= count
  }

  /// Writes the given text to the output stream.
  ///
  /// Before printing the text, this function will print any line-leading indentation or interior
  /// leading spaces that are required before the text itself.
  private func write(_ text: String) {
    if isAtStartOfLine {
      writeRaw(currentIndentation.indentation())
      spaceRemaining = maxLineLength - currentIndentation.length(in: configuration)
      isAtStartOfLine = false
    } else if pendingSpaces > 0 {
      writeRaw(String(repeating: " ", count: pendingSpaces))
    }
    writeRaw(text)
    consecutiveNewlineCount = 0
    pendingSpaces = 0
  }

  /// Print out the provided token, and apply line-wrapping and indentation as needed.
  ///
  /// This method takes a Token and it's length, and it keeps track of how much space is left on the
  /// current line it is printing on. If a token exceeds the remaning space, we break to a new line,
  /// and apply the appropriate level of indentation.
  ///
  /// - Parameters:
  ///   - token: The token to be printed.
  ///   - length: The length of the token (number of columns).
  private func printToken(token: Token, length: Int) {
    if self.printTokenStream {
      printDebugToken(token: token, length: length)
    }
    assert(length >= 0, "Token lengths must be positive")
    switch token {

    // Check if we need to force breaks in this group, and calculate the indentation to be used in
    // the group.
    case .open(let breaktype):
      // Determine if the break tokens in this group need to be forced.
      if (length > spaceRemaining || lastBreak), case .consistent = breaktype {
        forceBreakStack.append(true)
      } else {
        forceBreakStack.append(false)
      }

    case .close:
      forceBreakStack.removeLast()

    // Create a line break if needed. Calculate the indentation required and adjust spaceRemaining
    // accordingly.
    case .break(let kind, let size, _):
      lastBreakKind = kind
      var mustBreak = forceBreakStack.last ?? false
      var isContinuation = false

      switch kind {
      case .open:
        currentLineIsContinuation = false
        openDelimiterBreakStack.append(lineNumber)
        indentationStack.append(configuration.indentation)
      case .close(let closeMustBreak):
        guard let matchingOpenLineNumber = openDelimiterBreakStack.popLast() else {
          fatalError("Unmatched closing break")
        }
        indentationStack.removeLast()

        let isDifferentLine = lineNumber != matchingOpenLineNumber
        if closeMustBreak {
          // If it's a mandatory breaking close, then we must break (regardless of line length) if
          // the break is on a different line than its corresponding open break.
          mustBreak = isDifferentLine
        } else if spaceRemaining == 0 {
          // If there is no room left on the line, then we must force this break to fire so that the
          // next token that comes along (typically a closing bracket of some kind) ends up on the
          // next line.
          mustBreak = true
        } else {
          // Otherwise, if we're not force-breaking and we're on a different line than the
          // corresponding open, then the current line must effectively become a continuation line.
          // This ensures that any reset breaks that might follow on the same line are honored. For
          // example, the reset break before the open curly brace below must be made to fire so that
          // the brace can distinguish the argument lines from the block body.
          //
          //    if let someLongVariableName = someLongFunctionName(
          //      firstArgument: argumentValue)
          //    {
          //      ...
          //    }
          //
          // In this case, the preferred style would be to break before the parenthesis and place it
          // on the same line as the curly brace, but that requires quite a bit more contextual
          // information than is easily available. The user can, however, do so with discretionary
          // breaks (if they are enabled).
          currentLineIsContinuation = isDifferentLine
        }
      case .continue:
        isContinuation = true
      case .same:
        break
      case .reset:
        mustBreak = currentLineIsContinuation
      }

      if length > spaceRemaining || mustBreak {
        currentLineIsContinuation = isContinuation
        writeNewlines(1, discretionary: false)
        lastBreak = true
      } else {
        if isAtStartOfLine {
          // Make sure that the continuation status is correct even at the beginning of a line
          // (for example, after a newline token). This is necessary because a discretionary newline
          // might be inserted into the token stream before a continuation break, and the length of
          // that break might not be enough to satisfy the conditions above but we still need to
          // treat the line as a continuation.
          currentLineIsContinuation = isContinuation
        }
        enqueueSpaces(size)
        lastBreak = false
      }

    // Print out the number of spaces according to the size, and adjust spaceRemaining.
    case .space(let size):
      enqueueSpaces(size)

    // Apply `count` line breaks, calculate the indentation required, and adjust spaceRemaining.
    case .newlines(let count, let discretionary):
      currentLineIsContinuation = (lastBreakKind == .continue)
      writeNewlines(count, discretionary: discretionary)
      lastBreak = true

    // Print any indentation required, followed by the text content of the syntax token.
    case .syntax(let text):
      guard !text.isEmpty else { break }
      lastBreak = false
      write(text)
      spaceRemaining -= text.count

    case .comment(let comment, let wasEndOfLine):
      currentLineIsContinuation = false
      lastBreak = false

      write(comment.print(indent: currentIndentation))
      if wasEndOfLine {
        if comment.length > spaceRemaining {
          diagnose(.moveEndOfLineComment, at: comment.position)
        }
      } else {
        spaceRemaining -= comment.length
      }

    case .verbatim(let verbatim):
      writeRaw(verbatim.print(indent: currentIndentation))
      consecutiveNewlineCount = 0
      pendingSpaces = 0
      lastBreak = false
      spaceRemaining -= length
    }
  }

  /// Scan over the array of Tokens and calculate their lengths.
  ///
  /// This method is based on the `scan` function described in Derek Oppen's "Pretty Printing" paper
  /// (1979).
  ///
  /// - Returns: A String containing the formatted source code.
  public func prettyPrint() -> String {
    // Keep track of the indicies of the .open and .break token locations.
    var delimIndexStack = [Int]()
    // Keep a running total of the token lengths.
    var total = 0

    // Calculate token lengths
    for (i, token) in tokens.enumerated() {
      switch token {
      // Open tokens have lengths equal to the total of the contents of its group. The value is
      // calcualted when close tokens are encountered.
      case .open:
        lengths.append(-total)
        delimIndexStack.append(i)

      // Close tokens have a length of 0. Calculate the length of the corresponding open token, and
      // the previous break token (if any).
      case .close:
        lengths.append(0)

        // TODO(dabelknap): Handle the unwrapping more gracefully
        guard let index = delimIndexStack.popLast() else {
          print("Bad index 1")
          return ""
        }
        lengths[index] += total

        // TODO(dabelknap): Handle the unwrapping more gracefully
        if case .break = tokens[index] {
          guard let index = delimIndexStack.popLast() else {
            print("Bad index 2")
            return ""
          }
          lengths[index] += total
        }

      // Break lengths are equal to its size plus the token or group following it. Calculate the
      // length of any prior break tokens.
      case .break(_, let size, _):
        if let index = delimIndexStack.last, case .break = tokens[index] {
          lengths[index] += total
          delimIndexStack.removeLast()
        }

        lengths.append(-total)
        delimIndexStack.append(i)
        total += size

      // Space tokens have a length equal to its size.
      case .space(let size):
        lengths.append(size)
        total += size

      // The length of newlines are equal to the maximum allowed line length. Calculate the length
      // of any prior break tokens.
      case .newlines:
        if let index = delimIndexStack.last, case .break = tokens[index] {
          lengths[index] += total
          delimIndexStack.removeLast()
        }

        // Since newlines must always cause a line-break, we set their length as the full allowed
        // width of the line. This causes any enclosing groups to have a length exceeding the line
        // limit, and so the group must break and indent. e.g. single-line versus multi-line
        // function bodies.
        lengths.append(maxLineLength)
        total += maxLineLength

      // Syntax tokens have a length equal to the number of columns needed to print its contents.
      case .syntax(let text):
        lengths.append(text.count)
        total += text.count

      case .comment(let comment, let wasEndOfLine):
        lengths.append(comment.length)
        total += wasEndOfLine ? 0 : comment.length

      case .verbatim(let verbatim):
        var length: Int
        if verbatim.lines.count > 1 {
          length = maxLineLength
        } else if verbatim.lines.count == 0 {
          length = 0
        } else {
          length = verbatim.lines[0].count
        }
        lengths.append(length)
        total += length
      }
    }

    // There may be an extra break token that needs to have its length calculated.
    assert(delimIndexStack.count < 2, "Too many unresolved delmiter token lengths.")
    if let index = delimIndexStack.popLast() {
      if case .open = tokens[index] {
        assert(false, "Open tokens must be closed.")
      }
      lengths[index] += total
    }

    // Print out the token stream, wrapping according to line-length limitations.
    for i in 0..<tokens.count {
      printToken(token: tokens[i], length: lengths[i])
    }

    guard openDelimiterBreakStack.isEmpty else {
      fatalError("At least one .break(.open) was not matched by a .break(.close)")
    }

    return outputBuffer
  }

  /// Used to track the indentation level for the debug token stream output.
  var debugIndent: [Indent] = []

  /// Print out the token stream to the console for debugging.
  ///
  /// Indentation is applied to make identification of groups easier.
  private func printDebugToken(token: Token, length: Int) {
    func printDebugIndent() {
      print(debugIndent.indentation(), terminator: "")
    }

    switch token {
    case .syntax(let syntax):
      printDebugIndent()
      print("[SYNTAX \"\(syntax)\" Length: \(length)]")

    case .break(let kind, let size, let ignoresDiscretionary):
      printDebugIndent()
      print(
        "[BREAK Kind: \(kind) Size: \(size) Length: \(length) "
          + "Ignores Discretionary NL: \(ignoresDiscretionary)]")

    case .open(let breakstyle):
      printDebugIndent()
      switch breakstyle {
      case .consistent:
        print("[OPEN Consistent Length: \(length)]")
      case .inconsistent:
        print("[OPEN Inconsistent Length: \(length)]")
      }
      debugIndent.append(.spaces(2))

    case .close:
      debugIndent.removeLast()
      printDebugIndent()
      print("[CLOSE]")

    case .newlines(let N, let required):
      printDebugIndent()
      print("[NEWLINES N: \(N) Required: \(required) Length: \(length)]")

    case .space(let size):
      printDebugIndent()
      print("[SPACE Size: \(size) Length: \(length)]")

    case .comment(let comment, let wasEndOfLine):
      printDebugIndent()
      switch comment.kind {
      case .line:
        print("[COMMENT Line Length: \(length) EOL: \(wasEndOfLine)]")
      case .docLine:
        print("[COMMENT DocLine Length: \(length) EOL: \(wasEndOfLine)]")
      case .block:
        print("[COMMENT Block Length: \(length) EOL: \(wasEndOfLine)]")
      case .docBlock:
        print("[COMMENT DocBlock Length: \(length) EOL: \(wasEndOfLine)]")
      }
      printDebugIndent()
      print(comment.print(indent: debugIndent))

    case .verbatim(let verbatim):
      printDebugIndent()
      print("[VERBATIM Length: \(length)]")
      print(verbatim.print(indent: debugIndent))
    }
  }

  private func diagnose(_ message: Diagnostic.Message, at position: AbsolutePosition?) {
    let location: SourceLocation?
    if let position = position {
      location =
        SourceLocation(offset: position.utf8Offset, converter: context.sourceLocationConverter)
    } else {
      location = nil
    }
    context.diagnosticEngine?.diagnose(message, location: location)
  }
}

extension Diagnostic.Message {

  static let moveEndOfLineComment =
    Diagnostic.Message(.warning, "End-of-line comment exceeds the line length")
}
