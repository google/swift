import Foundation
import SwiftSyntax
import XCTest

@testable import Rules

public class NoLeadingUnderscoresTests: DiagnosingTestCase {
  public func testInvalidIdentifierNames() {
    let input =
    """
      let _foo = foo
      var good_name = 20
      var _badName, okayName, _wor_sEName = 20
      struct _baz {
        var x: Int {
          get {
            var a = 10
            var _b = 20
          }
          set {
            var _c = 10
            var d = 20
          }
        }

        init(foox z: Int, bar _y: Int) {}
        func _bazFunc(arg1: String, _arg2: Int) {}
        func quuxFunc(fooo _x: Int) {}
      }

      protocol _SomeProtocol {
        func _food()
      }

      struct Bag<_Element> {}
      func generic<_Arg>(x: _Arg) {}

      enum Numbers {
        case one
        case _two
        case three
      }

      func f() {
        var _x: Int = 10
        var y: Int = 20
      }
    """
    performLint(NoLeadingUnderscores.self, input: input)
    XCTAssertDiagnosed(.doNotLeadWithUnderscore(identifier: "_foo"))
    XCTAssertNotDiagnosed(.doNotLeadWithUnderscore(identifier: "good_name"))
    XCTAssertDiagnosed(.doNotLeadWithUnderscore(identifier: "_badName"))
    XCTAssertNotDiagnosed(.doNotLeadWithUnderscore(identifier: "okayName"))
    XCTAssertDiagnosed(.doNotLeadWithUnderscore(identifier: "_wor_sEName"))
    
    XCTAssertDiagnosed(.doNotLeadWithUnderscore(identifier: "_baz"))
    XCTAssertNotDiagnosed(.doNotLeadWithUnderscore(identifier: "x"))
    XCTAssertNotDiagnosed(.doNotLeadWithUnderscore(identifier: "a"))
    XCTAssertDiagnosed(.doNotLeadWithUnderscore(identifier: "_b"))
    XCTAssertDiagnosed(.doNotLeadWithUnderscore(identifier: "_c"))
    XCTAssertNotDiagnosed(.doNotLeadWithUnderscore(identifier: "d"))
    
    XCTAssertNotDiagnosed(.doNotLeadWithUnderscore(identifier: "init"))
    XCTAssertNotDiagnosed(.doNotLeadWithUnderscore(identifier: "foox"))
    XCTAssertNotDiagnosed(.doNotLeadWithUnderscore(identifier: "z"))
    XCTAssertNotDiagnosed(.doNotLeadWithUnderscore(identifier: "bar"))
    XCTAssertDiagnosed(.doNotLeadWithUnderscore(identifier: "_y"))
    
    XCTAssertDiagnosed(.doNotLeadWithUnderscore(identifier: "_bazFunc"))
    XCTAssertNotDiagnosed(.doNotLeadWithUnderscore(identifier: "arg1"))
    XCTAssertDiagnosed(.doNotLeadWithUnderscore(identifier: "_arg2"))
    
    XCTAssertNotDiagnosed(.doNotLeadWithUnderscore(identifier: "quuxFunc"))
    XCTAssertNotDiagnosed(.doNotLeadWithUnderscore(identifier: "fooo"))
    XCTAssertDiagnosed(.doNotLeadWithUnderscore(identifier: "_x"))
    
    XCTAssertDiagnosed(.doNotLeadWithUnderscore(identifier: "_SomeProtocol"))
    XCTAssertDiagnosed(.doNotLeadWithUnderscore(identifier: "_food"))
    
    XCTAssertDiagnosed(.doNotLeadWithUnderscore(identifier: "_Element"))
    XCTAssertNotDiagnosed(.doNotLeadWithUnderscore(identifier: "generic"))
    XCTAssertDiagnosed(.doNotLeadWithUnderscore(identifier: "_Arg"))
    XCTAssertNotDiagnosed(.doNotLeadWithUnderscore(identifier: "x"))
    
    XCTAssertNotDiagnosed(.doNotLeadWithUnderscore(identifier: "Numbers"))
    XCTAssertNotDiagnosed(.doNotLeadWithUnderscore(identifier: "one"))
    XCTAssertDiagnosed(.doNotLeadWithUnderscore(identifier: "_two"))
    XCTAssertNotDiagnosed(.doNotLeadWithUnderscore(identifier: "three"))
    
    XCTAssertNotDiagnosed(.doNotLeadWithUnderscore(identifier: "f"))
    XCTAssertDiagnosed(.doNotLeadWithUnderscore(identifier: "_x"))
    XCTAssertNotDiagnosed(.doNotLeadWithUnderscore(identifier: "y"))
  }
    
#if !os(macOS)
  static let allTests = [
    NoLeadingUnderscores.testInvalidIdentifierNames,
  ]
#endif
}
