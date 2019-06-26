//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2019 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import Foundation

/// This class takes the raw source text and scans through it searching for comment pairs of the
/// form:
///
///   3. |  // swift-format-disable: RuleName
///   4. |  let a = 123
///   5. |  // swift-format-enable: RuleName
///
/// This class records that `RuleName` is disabled for line 4. The rules themselves reference
/// RuleMask to see if it is disabled for the line it is currently examining.
public class RuleMask {

  /// Each rule has a list of ranges for which it is disabled.
  private var ruleMap: [String: [Range<Int>]] = [:]

  /// Regex to match the enable comments; rule name is in the first capture group.
  private let enablePattern = #"^\s*//\s*swift-format-enable:\s+(\S+)"#

  /// Regex to match the disable comments; rule name is in the first capture group.
  private let disablePattern = #"^\s*//\s*swift-format-disable:\s+(\S+)"#

  /// Rule enable regex object.
  private let enableRegex: NSRegularExpression

  /// Rule disable regex object.
  private let disableRegex: NSRegularExpression

  /// This takes the raw text of the source and generates a map of the rules specified for
  /// disable/enable and the line ranges for which they are disabled.
  public init(sourceText: String) {
    let sourceLines =
      sourceText.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)

    enableRegex = try! NSRegularExpression(pattern: enablePattern, options: [])
    disableRegex = try! NSRegularExpression(pattern: disablePattern, options: [])

    generateDictionary(sourceLines)
  }

  /// Generate the dictionary (ruleMap) from a list of the lines in the source.
  private func generateDictionary(_ sourceLines: [String]) {

    var disableStart: [String: Int] = [:]

    for (idx, line) in sourceLines.enumerated() {
      let nsrange = NSRange(line.startIndex..<line.endIndex, in: line)
      if let match = disableRegex.firstMatch(in: line, options: [], range: nsrange) {
        let matchRange = match.range(at: 1)
        if matchRange.location != NSNotFound, let range = Range(matchRange, in: line) {

          let rule = String(line[range])
          guard !disableStart.keys.contains(rule) else { continue }

          disableStart[rule] = idx + 1
        }
      }

      if let match = enableRegex.firstMatch(in: line, options: [], range: nsrange) {
        let matchRange = match.range(at: 1)
        if matchRange.location != NSNotFound, let range = Range(matchRange, in: line) {

          let rule = String(line[range])
          guard let startIdx = disableStart.removeValue(forKey: rule) else { continue }

          let exclusionRange = startIdx..<idx+1
          if ruleMap.keys.contains(rule) {
            ruleMap[rule]?.append(exclusionRange)
          }
          else {
            ruleMap[rule] = [exclusionRange]
          }
        }
      }
    }
  }

  /// Return if the given rule is disabled on the provided line.
  public func isDisabled(_ rule: String, line: Int) -> Bool {
    guard let ranges = ruleMap[rule] else { return false }
    for range in ranges {
      if range.contains(line) { return true }
    }
    return false
  }
}
