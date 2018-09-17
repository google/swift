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

import SwiftSyntax

extension Syntax {
  /// Performs a depth-first in-order traversal of the node to find the first
  /// node in its hierarchy that is a Token.
  public var firstToken: TokenSyntax? {
    if let tok = self as? TokenSyntax { return tok }
    for child in children {
      if let tok = child.firstToken { return tok }
    }
    return nil
  }

  /// Performs a depth-first reverse-order traversal of the node to find the last
  /// node in its hierarchy that is a Token.
  public var lastToken: TokenSyntax? {
    if let tok = self as? TokenSyntax { return tok }
    for child in children.reversed() {
      if let tok = child.lastToken { return tok }
    }
    return nil
  }

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

  /// Recursively walks through the tree to find the next token semantically
  /// after this node.
  public var nextToken: TokenSyntax? {
    var current: Syntax? = self

    // Walk up the parent chain, checking adjacent siblings after each node
    // until we find a node with a 'first token'.
    while let node = current {
      // If we've walked to the top, just stop.
      guard let parent = node.parent else { break }

      // If we're not the last child, search through each sibling until
      // we find a token.
      if node.indexInParent < parent.numberOfChildren {
        for idx in (node.indexInParent + 1)..<parent.numberOfChildren {
          let nextChild = parent.child(at: idx)

          // If there's a token, we're good.
          if let child = nextChild?.firstToken { return child }
        }
      }

      // If we've exhausted siblings, move up to the parent.
      current = parent
    }
    return nil
  }

  /// Recursively walks through the tree to find the token semantically
  /// before this node.
  public var previousToken: TokenSyntax? {
    var current: Syntax? = self

    // Walk up the parent chain, checking adjacent siblings after each node
    // until we find a node with a 'first token'.
    while let node = current {
      // If we've walked to the top, just stop.
      guard let parent = node.parent else { break }

      // If we're not the first child, search through each previous sibling until
      // we find a token.
      if node.indexInParent > 0 {
        for idx in (0..<node.indexInParent).reversed() {
          let nextChild = parent.child(at: idx)

          // If there's a token, we're good.
          if let child = nextChild?.lastToken { return child }
        }
      }

      // If we've exhausted siblings, move up to the parent.
      current = parent
    }
    return nil
  }
}
