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

import Foundation

struct Comment {
  enum Kind {
    case line, docLine, block, docBlock

    /// The length of the characters starting the comment.
    var prefixLength: Int {
      switch self {
      // `//`, `/*`, and `/**` all will have their continued lines prefixed with 3 characters.
      case .line, .block, .docBlock: return 2

      // `/// ` is 4 characters.
      case .docLine: return 3
      }
    }

    var prefix: String {
      switch self {
      case .line: return "//"
      case .block, .docBlock: return " "
      case .docLine: return "///"
      }
    }
  }
  let kind: Kind
  var text: String

  init(kind: Kind, text: String) {
    self.text = text
    self.kind = kind

    self.text.removeFirst(kind.prefixLength)

    switch kind {
    case .docBlock:
      self.text.removeLast(2)
    case .block:
      self.text.removeLast(2)
    default: break
    }
  }

  mutating func addText(_ text: String) {
    self.text += "\n" + text
  }

  func wordWrap(lineLength: Int) -> [String] {
    let maxLength = lineLength - (kind.prefixLength + 1)
    let scanner = Scanner(string: text)
    var lines = [String]()

    // FIXME: Word wrapping doesn't work for documentation comments, as we need to preserve all the
    //        intricacies of Markdown formatting.
    // FIXME: If there's a totally blank comment line, it doesn't get a prefix for some reason.
    // TODO: Allow for leading `*` characters for each line of a block comment.
    if kind == .docLine || kind == .docBlock {
      lines = text.split(separator: "\n").map { "\(kind.prefix)\($0)" }
    } else {
      var currentLine = ""
      var currentLineLength = 0
      var buffer: NSString! = ""
      while scanner.scanUpToCharacters(from: .whitespacesAndNewlines, into: &buffer) {
        let strBuf = buffer as String
        if currentLineLength + strBuf.count > maxLength {
          lines.append(currentLine)
          currentLine = ""
          currentLineLength = 0
        }
        currentLine += strBuf + " "
        currentLineLength += strBuf.count + 1
      }
      if currentLineLength > 0 {
        lines.append(currentLine.trimmingCharacters(in: .whitespaces))
      }
      for i in 0..<lines.count {
        lines[i] = "\(kind.prefix) \(lines[i])"
      }
    }
    switch kind {
    case .block:
      lines.insert("/*", at: 0)
      lines.append(" */")
    case .docBlock:
      lines.insert("/**", at: 0)
      lines.append(" */")
    default: break
    }
    return lines
  }
}
