import Foundation
import SwiftSyntax

let sourcesDir = URL(fileURLWithPath: #file)
                   .deletingLastPathComponent()
                   .deletingLastPathComponent()
let rulesDir =  sourcesDir.appendingPathComponent("Rules")
let outputFile =  sourcesDir.appendingPathComponent("swiftformat")
                            .appendingPathComponent("PopulatePipeline.swift")
let fm = FileManager.default

enum PassKind {
  case format, lint, file
}

/// A registry of format, lint, and file-level passes.
struct PassRegistry {

  /// A dictionary mapping the name of a linter and an array of the names of types it has
  /// overridden visitors for.
  var lintingPasses = [String: [String]]()

  /// A dictionary mapping the name of a formatter and an array of the names of types it has
  /// overridden visitors for.
  var formattingPasses = [String: [String]]()

  /// An array of file-level formatting passes.
  var filePasses = [String]()
}

var registry = PassRegistry()

// For each file in the Rules directory, find if there is a class that inherits from either
// - SyntaxLintRule
// - SyntaxFormatRule
// - FileRule
// If so, check to see if it's overridden any of the visitor methods. If it has, keep track of it.

for baseName in fm.enumerator(atPath: rulesDir.path)! {
  guard let baseName = baseName as? String, baseName.hasSuffix(".swift") else { continue }
  let fileURL = rulesDir.appendingPathComponent(baseName)
  let sourceFile = try SyntaxTreeParser.parse(fileURL)

  for stmt in sourceFile.statements {
    guard let classDecl = stmt.item as? ClassDeclSyntax else { continue }
    let className = classDecl.identifier.text
    guard let inheritanceClause = classDecl.inheritanceClause else { continue }
    var maybeKind: PassKind? = nil
    for item in inheritanceClause.inheritedTypeCollection {
      guard let ident = item.typeName as? SimpleTypeIdentifierSyntax else { continue }
      switch ident.name.text {
      case "SyntaxLintRule": maybeKind = .lint
      case "SyntaxFormatRule": maybeKind = .format
      case "FileRule": maybeKind = .file
      default: continue
      }
    }
    guard let kind = maybeKind else { continue }

    if kind == .file {
      registry.filePasses.append(className)
      continue
    }
    for member in classDecl.members.members {
      guard let function = member as? FunctionDeclSyntax,
            let modifiers = function.modifiers else {
        continue
      }
      guard modifiers.contains(where: { $0.name.text == "override" }) else { continue }
      guard function.identifier.text == "visit" else { continue }
      let params = function.signature.input.parameterList
      guard let firstType = params.first?.type as? SimpleTypeIdentifierSyntax,
            params.count == 1 else {
        continue
      }
      let typeName = firstType.name.text
      switch kind {
      case .lint:
        registry.lintingPasses[className, default: []].append(typeName)
      case .format:
        registry.formattingPasses[className, default: []].append(typeName)
      case .file:
        fatalError("should have been handled earlier")
      }
    }
  }
}

extension FileHandle: TextOutputStream {
  /// Writes the provided string as data to a file output stream.
  public func write(_ string: String) {
    guard let data = string.data(using: .utf8) else { return }
    write(data)
  }
}

// Delete the existing pipeline population file.

if fm.fileExists(atPath: outputFile.path) {
  try fm.removeItem(at: outputFile)
}
fm.createFile(atPath: outputFile.path, contents: nil, attributes: nil)
let handle = try FileHandle(forWritingTo: outputFile)

// Generate a file with a populatePipeline(_:) function we can call to add all the existing
// formatting passes.

handle.write(
  """
  // This file is automatically generated with generate-pipeline. Do Not Edit!
  import Core
  import Rules
  import SwiftSyntax

  /// Populates the provided pipeline with all implemented formatting and linting passes.
  ///
  /// - Parameter pipeline: The pipeline to populate with passes.
  func populate(_ pipeline: Pipeline) {
    /// MARK: File Passes

  """
)
for fileRule in registry.filePasses {
  handle.write("  pipeline.addFileRule(\(fileRule).self)\n")
}
handle.write("\n  /// MARK: Formatting Passes\n")
for (className, types) in registry.formattingPasses {
  handle.write(
    """

      pipeline.addFormatter(
        \(className).self,
        for:
          \(types.map { $0 + ".self" }.joined(separator: ",\n      "))
      )

    """)
}
handle.write("\n  /// MARK: Linting Passes\n")
for (className, types) in registry.lintingPasses {
  handle.write(
    """

      pipeline.addLinter(
        \(className).self,
        for:
          \(types.map { $0 + ".self" }.joined(separator: ",\n      "))
      )

    """
  )
}
handle.write("}\n")
