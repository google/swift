import Foundation
import SwiftSyntax

/// A rule that lints a given file.
open class SyntaxLintRule: SyntaxVisitor, Rule {
  /// The context in which the rule is executed.
  public let context: Context

  /// Creates a new SyntaxLintRule in the given context.
  public required init(context: Context) {
    self.context = context
  }
}

extension Rule {
  /// Emits the provided diagnostic to the diagnostic engine.
  ///
  /// - Parameters:
  ///   - message: The diagnostic message to emit.
  ///   - location: The source location which the diagnostic should be attached.
  ///   - actions: A set of actions to add notes, highlights, and fix-its to diagnostics.
  public func diagnose(
    _ message: Diagnostic.Message,
    on node: Syntax?,
    actions: ((inout Diagnostic.Builder) -> Void)? = nil
  ) {
    context.diagnosticEngine?.diagnose(
      message.withRule(self),
      location: node?.startLocation(in: context.fileURL),
      actions: actions
    )
  }
}
