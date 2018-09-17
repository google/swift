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

import Foundation
import SwiftSyntax

/// Rewriter that changes the indentation of a given code block with the
/// provided indentation adjustment.
private final class ReindentBlock: SyntaxRewriter {
  let adjustment: Int
  
  init(adjustment: Int) {
    self.adjustment = adjustment
  }
  
  override func visit(_ token: TokenSyntax) -> Syntax {
    guard token.leadingTrivia.containsNewlines else { return token }
    
    var newTrivia: [TriviaPiece] = []
    var previousIsNewline = false
    
    for piece in token.leadingTrivia {
      if case .newlines = piece {
        newTrivia.append(piece)
        previousIsNewline = true
        continue
      } else {
        guard previousIsNewline else { newTrivia.append(piece); continue }
        if case .spaces(let n) = piece {
          // Replace current indent
          let newIndent = n + adjustment
          let newPiece = (newIndent > 0) ? Trivia.spaces(newIndent) : .spaces(0)
          newTrivia.append(contentsOf: newPiece)
        } else {
          // Insert new indent at front
          let newPiece = (adjustment > 0) ? Trivia.spaces(adjustment) : .spaces(0)
          // TODO(laurenwhite): warning for indentation without enough spaces to be adjusted?
          newTrivia.append(contentsOf: newPiece)
          newTrivia.append(piece)
        }
        previousIsNewline = false
      }
    }
    return token.withLeadingTrivia(Trivia(pieces: newTrivia))
  }
  
}

/// Replaces the given block with new indentation from the provided adjustment.
/// - Parameters:
///   - block: The code block whose containing items will be reindented
///   - adjustment: The number of spaces by which the current indentation will be moved. This
///                 integer may be negative (moves left) or positive (moves right).
func reindentBlock(block: CodeBlockSyntax, adjustment: Int) -> Syntax {
  return ReindentBlock(adjustment: adjustment).visit(block)
}
