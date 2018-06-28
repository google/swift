import Core
import Foundation
import SwiftSyntax

/// Numeric literals should be grouped with `_`s to delimit common separators.
/// Specifically, decimal numeric literals should be grouped every 3 numbers, hexadecimal every 4,
/// and binary every 8.
///
/// Lint: If a numeric literal is too long and should be grouped, a lint error is raised.
///
/// Format: All numeric literals that should be grouped will have `_`s inserted where appropriate.
///
/// TODO: Minimum numeric literal length bounds and numeric groupings selected arbitrarily, could
///       be  reevaluated.
///
/// - SeeAlso: https://google.github.io/swift#numeric-literals
public final class GroupNumericLiterals: SyntaxFormatRule {
  public override func visit(_ node: IntegerLiteralExprSyntax) -> ExprSyntax {
    
    var strDigits = node.digits.text
    guard !strDigits.contains("_") else { return node }
    
    let isNegative = strDigits.first == "-"
    strDigits = isNegative ? String(strDigits.dropFirst()) : strDigits
    
    var newDigits = ""
    
    switch strDigits.prefix(2) {
    case "0x":
      // Hexadecimal
      let digitsNoPrefix = String(strDigits.dropFirst(2))
      guard let intDigits = Int(digitsNoPrefix, radix: 16) else { return node }
      guard intDigits >= 0x1000_0000 else { return node }
      diagnose(.groupNumericLiteral(by: 4), on: node)
      newDigits = "0x" + groupDigits(digitStr: digitsNoPrefix, by: 4)
    case "0b":
      // Binary
      let digitsNoPrefix = String(strDigits.dropFirst(2))
      guard let intDigits = Int(digitsNoPrefix, radix: 2) else { return node }
      guard intDigits >= 0b1_000000000 else { return node }
      diagnose(.groupNumericLiteral(by: 8), on: node)
      newDigits = "0b" + groupDigits(digitStr: digitsNoPrefix, by: 8)
    case "0o":
      // Octal
      return node
    default:
      // Decimal
      guard let intDigits = Int(strDigits) else { return node }
      guard intDigits >= 1_000_000 else { return node }
      diagnose(.groupNumericLiteral(by: 3), on: node)
      newDigits = groupDigits(digitStr: strDigits, by: 3)
    }
    
    newDigits = isNegative ? "-" + newDigits : newDigits
    return node.withDigits(SyntaxFactory.makeIdentifier(newDigits))
  }
  
  func groupDigits(digitStr: String, by: Int) -> String {
    var newGrouping = Array(digitStr)
    var i = 1
    while i * by < digitStr.count {
      newGrouping.insert("_", at: digitStr.count - i * by)
      i += 1
    }
    return String(newGrouping)
  }
}

extension Diagnostic.Message {
  static func groupNumericLiteral(by: Int) -> Diagnostic.Message {
    let ending = by == 3 ? "rd" : "th"
    return .init(.warning, "Group numeric literal using '_' every \(by)\(ending) number")
  }
}
