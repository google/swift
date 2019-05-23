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
import SwiftSyntax

// These rules will not be added to the pipeline.
let suppressRules = ["UseEarlyExits", "UseWhereClausesInForLoops"]

/// Collects information about rules in the formatter code base.
final class RuleCollector {
  /// Information about a detected rule.
  private struct DetectedRule {
    /// The type name of the rule.
    let typeName: String

    /// The members defined by the rule type.
    let members: MemberDeclListSyntax

    /// Indicates whether the rule can format code (all rules can lint).
    let canFormat: Bool
  }

  /// A list of all rules that can lint (thus also including format rules) found in the code base.
  var allLinters = Set<String>()

  /// A list of all the format-only rules found in the code base.
  var allFormatters = Set<String>()

  /// A dictionary mapping syntax node types to the lint/format rules that visit them.
  var syntaxNodeLinters = [String: [String]]()

  /// Populates the internal collections with rules in the given directory.
  ///
  /// - Parameter url: The file system URL that should be scanned for rules.
  func collect(from url: URL) throws {
    // For each file in the Rules directory, find types that either conform to SyntaxLintRule or
    // inherit from SyntaxFormatRule.
    let fm = FileManager.default
    guard let rulesEnumerator = fm.enumerator(atPath: url.path) else {
      fatalError("Could not list the directory \(url.path)")
    }

    for baseName in rulesEnumerator {
      // Ignore files that aren't Swift source files.
      guard let baseName = baseName as? String, baseName.hasSuffix(".swift") else { continue }

      let fileURL = url.appendingPathComponent(baseName)
      let sourceFile = try SyntaxParser.parse(fileURL)

      for statement in sourceFile.statements {
        guard let detectedRule = self.detectedRule(at: statement) else { continue }

        if detectedRule.canFormat {
          // Format rules just get added to their own list; we run them each over the entire tree in
          // succession.
          allFormatters.insert(detectedRule.typeName)
        }

        // Lint rules (this includes format rules, which can also lint) get added to a mapping over
        // the names of the types they touch so that they can be interleaved into one pass over the
        // tree.
        allLinters.insert(detectedRule.typeName)
        for member in detectedRule.members {
          guard let function = member.decl as? FunctionDeclSyntax else { continue }
          guard function.identifier.text == "visit" else { continue }
          let params = function.signature.input.parameterList
          guard let firstType = params.firstAndOnly?.type as? SimpleTypeIdentifierSyntax else {
            continue
          }

          let nodeType = firstType.name.text
          syntaxNodeLinters[nodeType, default: []].append(detectedRule.typeName)
        }
      }
    }
  }

  /// Determine the rule kind for the declaration in the given statement, if any.
  private func detectedRule(at statement: CodeBlockItemSyntax) -> DetectedRule? {
    let typeName: String
    let members: MemberDeclListSyntax
    let maybeInheritanceClause: TypeInheritanceClauseSyntax?

    if let classDecl = statement.item as? ClassDeclSyntax {
      typeName = classDecl.identifier.text
      members = classDecl.members.members
      maybeInheritanceClause = classDecl.inheritanceClause
    }
    else if let structDecl = statement.item as? StructDeclSyntax {
      typeName = structDecl.identifier.text
      members = structDecl.members.members
      maybeInheritanceClause = structDecl.inheritanceClause
    }
    else {
      return nil
    }

    // Make sure the rule isn't suppressed, and it must have an inheritance clause.
    guard !suppressRules.contains(typeName), let inheritanceClause = maybeInheritanceClause else {
      return nil
    }

    // Scan through the inheritance clause to find one of the protocols/types we're interested in.
    for inheritance in inheritanceClause.inheritedTypeCollection {
      guard let identifier = inheritance.typeName as? SimpleTypeIdentifierSyntax else {
        continue
      }

      switch identifier.name.text {
      case "SyntaxLintRule":
        return DetectedRule(typeName: typeName, members: members, canFormat: false)
      case "SyntaxFormatRule":
        return DetectedRule(typeName: typeName, members: members, canFormat: true)
      default: continue
      }
    }

    return nil
  }
}
