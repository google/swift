//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2018 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import SwiftSyntax

extension Syntax {
  /// Walks up from the current node to find the nearest node that is an
  /// Expr, Stmt, or Decl.
  public var containingExprStmtOrDecl: Syntax? {
    var node: Syntax? = self
    while let parent = node?.parent {
      if parent is ExprSyntax ||
         parent is StmtSyntax ||
         parent is DeclSyntax {
        return parent
      }
      node = parent
    }
    return nil
  }
}

extension SyntaxCollection {

  /// Indicates whether the syntax collection is empty.
  public var isEmpty: Bool {
    var iterator = makeIterator()
    return iterator.next() == nil
  }

  /// The first element in the syntax collection, or nil if it is empty.
  public var first: Element? {
    var iterator = makeIterator()
    guard let first = iterator.next() else { return nil }
    return first
  }

  /// The first element in the syntax collection if it is the *only* element, or nil otherwise.
  public var firstAndOnly: Element? {
    var iterator = makeIterator()
    guard let first = iterator.next() else { return nil }
    guard iterator.next() == nil else { return nil }
    return first
  }

  /// The last element in the syntax collection, or nil if it is empty.
  public var last: Element? {
    var last: Element? = nil
    var iterator = makeIterator()
    while let current = iterator.next() { last = current }
    return last
  }
}
