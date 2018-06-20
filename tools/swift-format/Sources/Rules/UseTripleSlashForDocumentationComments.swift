import Core
import Foundation
import SwiftSyntax

/// Documentation comments must use the `///` form.
///
/// Flag comments (e.g. `// TODO(username):`) are exempted from this rule.
///
/// This is similar to `NoBlockComments` but is meant to prevent multi-line comments that use `//`.
///
/// Lint: If a declaration has a multi-line comment preceding it and that comment is not in `///`
///       form, a lint error is raised.
///
/// Format: If a declaration has a multi-line comment preceding it and that comment is not in `///`
///         form, it is converted to the `///` form.
///
/// - SeeAlso: https://google.github.io/swift#general-format
public final class UseTripleSlashForDocumentationComments: SyntaxLintRule {

    public override func visit(_ node: InitializerDeclSyntax) {
        diagnoseTripleSlashForDocumentionComments(node)
        super.visit(node)
    }

    public override func visit(_ node: DeinitializerDeclSyntax) {
        diagnoseTripleSlashForDocumentionComments(node)
        super.visit(node)
    }

    public override func visit(_ node: ProtocolDeclSyntax) {
        diagnoseTripleSlashForDocumentionComments(node)
        super.visit(node)
    }

    public override func visit(_ node: EnumDeclSyntax) {
        diagnoseTripleSlashForDocumentionComments(node)
        super.visit(node)
    }

    public override func visit(_ node: StructDeclSyntax) {
        diagnoseTripleSlashForDocumentionComments(node)
        super.visit(node)
    }

    public override func visit(_ node: ClassDeclSyntax) {
        diagnoseTripleSlashForDocumentionComments(node)
        super.visit(node)
    }

    public override func visit(_ node: ExtensionDeclSyntax) {
        diagnoseTripleSlashForDocumentionComments(node)
        super.visit(node)
    }

    public override func visit(_ node: VariableDeclSyntax) {
        diagnoseTripleSlashForDocumentionComments(node)
        super.visit(node)
    }

    public override func visit(_ node: FunctionDeclSyntax) {
        diagnoseTripleSlashForDocumentionComments(node)
        super.visit(node)
    }

    public override func visit(_ node: TypealiasDeclSyntax) {
        diagnoseTripleSlashForDocumentionComments(node)
        super.visit(node)
    }

    public override func visit(_ node: AssociatedtypeDeclSyntax) {
        diagnoseTripleSlashForDocumentionComments(node)
        super.visit(node)
    }

    private func diagnoseTripleSlashForDocumentionComments(_ node: DeclSyntax) {
        guard let trivia = node.firstToken?.leadingTrivia.reversed() else {
            return
        }

        for (index, piece) in trivia.enumerated() {
            switch piece {
            case .lineComment:
                guard index < trivia.count - 1 else {
                    continue
                }

                var previous = trivia[index + 1]

                if case .newlines = previous, index < trivia.count - 2 {
                    previous = trivia[index + 2]
                }

                if case .lineComment = previous {
                    diagnose(.documentationCommentsMustUseTripleSlashForm(), on: node)
                }
            case .docBlockComment:
                diagnose(.documentationCommentsMustUseTripleSlashForm(), on: node)
            default:
                break
            }
        }
    }
}

extension Diagnostic.Message {
    static func documentationCommentsMustUseTripleSlashForm() -> Diagnostic.Message {
        return .init(.error, "Documentation comments must use the `///` form.")
    }
}
