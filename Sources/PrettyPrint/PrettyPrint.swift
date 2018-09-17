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
import Core
import SwiftSyntax

#if os(Linux)
import Glibc
#else
import Darwin
#endif

// TODO(harlan): Comment this whole file.

// Characters used in debug mode to mark breaks, groups, and other points of interest.
fileprivate let spaceMarker = "\u{00B7}"
fileprivate let breakMarker = "\u{23CE}"
fileprivate let openGroupMarker = "\u{27EC}"
fileprivate let closeGroupMarker = "\u{27ED}"

/// PrettyPrinter takes a Syntax node and outputs a well-formatted, reindented reproduction of the
/// code to stdout.
public class PrettyPrinter {
  private let configuration: Configuration
  private let maxLineLength: Int
  private var tokens: [Token]
  private var outputBuffer: String = ""

  // The number of spaces remaining on the current line.
  private var spaceRemaining: Int

  // Keep track of the token lengths.
  private var lengths = [Int]()

  // Did the previous token trigger a newline?
  private var lastBreak = false

  // Keep track of the indentation level of the current group as the number of blank spaces.
  private var indentStack = [0]

  // The first token of a group must be indented according to it's outer group. Use this stack when
  // printing the indent of the first token in a group. Subsequent tokens will use the indent of the
  // current group.
  private var breakStack = [0]

  // Do we force breaks (for consistent breaking) within the current group?
  private var forceBreakStack = [false]

  /// If true, the pretty printer will output control characters that indicate where groups and
  /// breaks occur in the formatted output.
  private var isDebugMode: Bool

  /// The current index (0..<6) of the color to be used for the next color group.
  private var currentDebugGroupMarkerColor = 0

  /// We cycle through ANSI colors 31...36 for group brackets.
  private let groupMarkerColorCount = 6

  /// The ANSI color code string for the current group color (used in debug mode).
  private var currentGroupColorString: String {
    return Ansi.color(currentDebugGroupMarkerColor + 1)
  }

  /// Creates a new PrettyPrinter with the provided formatting configuration.
  ///
  /// - Parameters:
  ///   - configuration: The configuration used to decide whitespace or breaking behavior.
  ///   - node: The node to be pretty printed.
  public init(configuration: Configuration, node: Syntax, isDebugMode: Bool) {
    self.configuration = configuration
    self.tokens = node.makeTokenStream(configuration: configuration)
    self.maxLineLength = configuration.lineLength
    self.isDebugMode = isDebugMode
    self.spaceRemaining = self.maxLineLength
  }

  func write<S: StringProtocol>(_ str: S) {
    outputBuffer.append(String(str))
  }

  /// Print out the provided token, and apply line-wrapping and indentation as needed.
  ///
  /// This method takes a Token and it's length, and it keeps track of how much space is left on the
  /// current line it is printing on. If a token exceeds the remaning space, we break to a new line,
  /// and apply the appropriate level of indentation.
  private func printToken(token: Token, length: Int) {
    switch token {

    case .open(let breaktype, let offset):
      if isDebugMode {
        writeOpenGroupDebugMarker()
      }

      if length > spaceRemaining || lastBreak, case .consistent = breaktype {
        forceBreakStack.append(true)
      } else {
        forceBreakStack.append(false)
      }

      let indentValue = indentStack.last ?? 0
      let breakValue = breakStack.last ?? 0
      indentStack.append(indentValue + offset)
      breakStack.append(breakValue)

    case .close:
      if isDebugMode {
        writeCloseGroupDebugMarker()
      }
      forceBreakStack.removeLast()
      indentStack.removeLast()
      breakStack.removeLast()

    case .break(let size):
      if isDebugMode {
        if let forcebreak = forceBreakStack.last, forcebreak {
          writeBreakDebugMarker(style: .consistent)
        } else {
          writeBreakDebugMarker(style: .inconsistent)
        }
      }

      let forcebreak = forceBreakStack.last ?? false
      if length > spaceRemaining || forcebreak {
        // Update the top of the breakStack to reflect the indentation level of the current group.
        let indentValue = indentStack.last ?? 0
        breakStack.removeLast()
        breakStack.append(indentValue)

        spaceRemaining = maxLineLength - indentValue
        write("\n")
        lastBreak = true
      } else {
        writeSpaces(size)
        spaceRemaining -= size
        lastBreak = false
      }

    case .newlines(let N):
      // Newlines are treated as forced `breaks` with a size of zero.
      let indentValue = indentStack.last ?? 0
      breakStack.removeLast()
      breakStack.append(indentValue)

      spaceRemaining = maxLineLength - indentValue
      write(String(repeating: "\n", count: N))
      lastBreak = true


    case .syntax(let syntaxToken):
      if lastBreak {
        // If the last token created  a newline, we need to apply indentation.
        let indentValue = breakStack.last ?? 0
        writeSpaces(indentValue)
        lastBreak = false
      }
      write(syntaxToken.text)
      spaceRemaining -= syntaxToken.text.count

    // TODO(dabelknap): Implement comments
    case .comment: ()
    }
  }

  /// Scan over the array of Tokens and calculate their lengths.
  ///
  /// This method is based on the `scan` function described in Derek Oppen's "Pretty Printing" paper
  /// (1979).
  public func prettyPrint() -> String {
    var delimIndexStack = [Int]() // Keep track of the indicies of the .open token locations.
    var total = 0 // Keep a running total of the token lengths.

    // Calculate token lengths
    for (i, token) in tokens.enumerated() {
      switch token {
      case .open:
        lengths.append(-total)
        delimIndexStack.append(i)

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

      case .break(let size):
        if let index = delimIndexStack.last, case .break = tokens[index] {
          lengths[index] += total
          delimIndexStack.removeLast()
        }

        lengths.append(-total)
        delimIndexStack.append(i)
        total += size

      case .newlines:
        if let index = delimIndexStack.last, case .break = tokens[index] {
          lengths[index] += total
          delimIndexStack.removeLast()
        }

        lengths.append(-total)
        delimIndexStack.append(i)
        total += 1

      case .syntax(let syntaxToken):
        lengths.append(syntaxToken.text.count)
        total += syntaxToken.text.count

      // TODO(dabelknap): Implement comments
      case .comment: ()
      }
    }

    // Update any remaining unresolved .open token lengths
    if let index = delimIndexStack.popLast() {
      lengths[index] += total
    }

    // Print out the token stream, wrapping according to line-length limitations.
    for i in 0..<tokens.count {
      printToken(token: tokens[i], length: lengths[i])
    }
    return outputBuffer
  }

  /// Writes a consistent or inconsistent break marker in debug mode.
  ///
  /// Breaks are indicated with the Unicode "RETURN SYMBOL" (⏎). Consistent breaks will be displayed
  /// in green and inconsistent breaks in yellow.
  ///
  /// - Parameter style: The break style to display.
  private func writeBreakDebugMarker(style: BreakStyle) {
    let breakColor: String
    switch style {
    case .consistent: breakColor = Ansi.green
    case .inconsistent: breakColor = Ansi.yellow
    }
    write(Ansi.bold)
    write(breakColor)
    write(breakMarker)
    write(Ansi.reset)
  }

  /// Writes a tortoise shell bracket indicating the beginning of a token group.
  ///
  /// Group markers are cycled through six different colors to make it easier to identify adjacent
  /// and nested groups.
  private func writeOpenGroupDebugMarker() {
    write(Ansi.bold)
    write(currentGroupColorString)
    write(openGroupMarker)
    write(Ansi.reset)
    currentDebugGroupMarkerColor = (currentDebugGroupMarkerColor + 1) % groupMarkerColorCount
  }

  /// Writes a tortoise shell bracket indicating the end of a token group.
  ///
  /// Group markers are cycled through six different colors to make it easier to identify adjacent
  /// and nested groups.
  private func writeCloseGroupDebugMarker() {
    currentDebugGroupMarkerColor = currentDebugGroupMarkerColor - 1
    if currentDebugGroupMarkerColor < 0 {
      currentDebugGroupMarkerColor = groupMarkerColorCount - 1
    }
    write(Ansi.bold)
    write(currentGroupColorString)
    write(closeGroupMarker)
    write(Ansi.reset)
  }

  /// Writes the given number of spaces to the output.
  ///
  /// If debug mode is enabled, spaces are rendered as gray Unicode MIDDLE DOT characters.
  private func writeSpaces(_ count: Int) {
    if isDebugMode {
      write(Ansi.brightBlack)
      write(String(repeating: spaceMarker, count: count))
      write(Ansi.reset)
    } else {
      if count == 1 {
        write(" ")
      } else {
        write(String(repeating: " ", count: count))
      }
    }
  }
}

/// Convenience properties/functions to access ANSI color code strings, respecting whether or not
/// output is being written to a terminal.
enum Ansi {

  /// True if stdout is a terminal (as opposed to a pipe or a redirection).
  static private var isTerminal: Bool { return isatty(1) != 0 }

  /// The ANSI color code string that makes subsequent text bold.
  static var bold: String { return isTerminal ? "\u{001b}[1m" : "" }

  /// The ANSI color code string that makes subsequent text reset to normal appearance.
  static var reset: String { return isTerminal ? "\u{001b}[0m" : "" }

  /// The ANSI color code string that makes subsequent text bright black.
  static var brightBlack: String { return "\u{001b}[30;1m" }

  /// The ANSI color code string that makes subsequent text green.
  static var green: String { return color(2) }

  /// The ANSI color code string that makes subsequent text yellow.
  static var yellow: String { return color(3) }

  /// The ANSI color code string that makes subsequent text render in the given color.
  ///
  /// The number 30 is added to the given index to determine the actual color code.
  static func color(_ index: Int) -> String { return isTerminal ? "\u{001b}[\(30 + index)m" : "" }
}
