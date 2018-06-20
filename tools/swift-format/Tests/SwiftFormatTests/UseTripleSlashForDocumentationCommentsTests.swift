import Foundation
import SwiftSyntax
import XCTest

@testable import Rules

public class UseTripleSlashForDocumentationCommentsTests: DiagnosingTestCase {

    public func testFuncSingleLineComment() {
        let input =
            """
            // A single line comment
            func someFunc() {}
            """

        performLint(UseTripleSlashForDocumentationComments.self, input: input)
        XCTAssertNotDiagnosed(.documentationCommentsMustUseTripleSlashForm())
    }

    public func testFuncMultipleLineComments() {
        let input =
            """
            // Line comments
            // over more than one line
            func someFunc() {}
            """

        performLint(UseTripleSlashForDocumentationComments.self, input: input)
        XCTAssertDiagnosed(.documentationCommentsMustUseTripleSlashForm())
    }

    // MARK: - Protocol

    public func testProtocolSingleLineComment() {
        let input =
            """
            // A single line comment
            protocol Foo {}
            """
        
        performLint(UseTripleSlashForDocumentationComments.self, input: input)
        XCTAssertNotDiagnosed(.documentationCommentsMustUseTripleSlashForm())
    }

    public func testProtocolMultipleLineComments() {
        let input =
            """
            // Line comments
            // over more than one line
            protocol Foo {}
            """

        performLint(UseTripleSlashForDocumentationComments.self, input: input)
        XCTAssertDiagnosed(.documentationCommentsMustUseTripleSlashForm())
    }

    public func testProtocolBlockComments() {
        let input =
            """
            /**
            Anything in here.
            */
            protocol Foo {}
            """
        performLint(UseTripleSlashForDocumentationComments.self, input: input)
        XCTAssertDiagnosed(.documentationCommentsMustUseTripleSlashForm())
    }

    // MARK: - Enum

    // MARK: - Struct

    // MARK: - Class

    public func testClassSingleLineComment() {
        let input =
            """
            // A single line comment
            class Foo {}
            """

        performLint(UseTripleSlashForDocumentationComments.self, input: input)
        XCTAssertNotDiagnosed(.documentationCommentsMustUseTripleSlashForm())
    }

    public func testClassMultipleLineComments() {
        let input =
            """
            // Line comments
            // over more than one line
            class Foo {}
            """

        performLint(UseTripleSlashForDocumentationComments.self, input: input)
        XCTAssertDiagnosed(.documentationCommentsMustUseTripleSlashForm())
    }

    public func testClassBlockComments() {
        let input =
            """
            /**
            Anything in here.
            */
            class Foo {}
            """
        performLint(UseTripleSlashForDocumentationComments.self, input: input)
        XCTAssertDiagnosed(.documentationCommentsMustUseTripleSlashForm())
    }

    // MARK: - Extension
}
