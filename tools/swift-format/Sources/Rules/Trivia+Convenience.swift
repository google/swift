import SwiftSyntax

extension Trivia {
  /// Returns the number of whitespace characters after this node.
  var numberOfSpaces: Int {
    var count = 0
    for piece in self {
      if case .tabs = piece { count += 1 }
      guard case .spaces(let n) = piece else { continue }
      count += n
    }
    return count
  }

  /// Returns this set of trivia, without any whitespace characters.
  func withoutSpaces() -> Trivia {
    return Trivia(pieces: filter {
      if case .spaces = $0 { return false }
      if case .tabs = $0 { return false }
      return true
    })
  }

  /// Returns this set of trivia without any trailing whitespace characters.
  func withoutTrailingSpaces() -> Trivia {
    var pieces = [TriviaPiece]()
    guard var prev = first else { return self }
    for piece in dropFirst() {
      switch (prev, piece) {
      case (.spaces(_), .newlines(_)),
           (.tabs(_), .newlines(_)):
        prev = piece
      default:
        pieces.append(prev)
        prev = piece
      }
    }
    pieces.append(prev)
    return Trivia.init(pieces: pieces).condensed()
  }

  /// Returns this set of trivia, without any newlines.
  func withoutNewlines() -> Trivia {
    return Trivia(pieces: filter {
      if case .newlines = $0 { return false }
      return true
    })
  }

  /// Returns this set of trivia, with all spaces removed except for one at the
  /// end.
  func withOneTrailingSpace() -> Trivia {
    return withoutSpaces() + .spaces(1)
  }

  /// Returns this set of trivia, with all spaces removed except for one at the
  /// beginning.
  func withOneLeadingSpace() -> Trivia {
    return .spaces(1) + withoutSpaces()
  }

  /// Returns this set of trivia, with all newlines removed except for one.
  func withOneLeadingNewline() -> Trivia {
    return .newlines(1) + withoutNewlines()
  }

  /// Returns this set of trivia, with all newlines removed except for one.
  func withOneTrailingNewline() -> Trivia {
    return withoutNewlines() + .newlines(1)
  }

  /// Walks through trivia looking for multiple separate trivia entities with
  /// the same base kind, and condenses them.
  /// `[.spaces(1), .spaces(2)]` becomes `[.spaces(3)]`.
  func condensed() -> Trivia {
    guard var prev = first else { return self }
    var pieces = [TriviaPiece]()
    for piece in dropFirst() {
      switch (prev, piece) {
      case (.spaces(let l), .spaces(let r)):
        prev = .spaces(l + r)
      case (.tabs(let l), .tabs(let r)):
        prev = .tabs(l + r)
      case (.newlines(let l), .newlines(let r)):
        prev = .newlines(l + r)
      case (.carriageReturns(let l), .carriageReturns(let r)):
        prev = .carriageReturns(l + r)
      case (.carriageReturnLineFeeds(let l), .carriageReturnLineFeeds(let r)):
        prev = .carriageReturnLineFeeds(l + r)
      case (.verticalTabs(let l), .verticalTabs(let r)):
        prev = .verticalTabs(l + r)
      case (.garbageText(let l), .garbageText(let r)):
        prev = .garbageText(l + r)
      case (.backticks(let l), .backticks(let r)):
        prev = .backticks(l + r)
      case (.formfeeds(let l), .formfeeds(let r)):
        prev = .formfeeds(l + r)
      default:
        pieces.append(prev)
        prev = piece
      }
    }
    pieces.append(prev)
    return Trivia(pieces: pieces)
  }

  /// Returns `true` if this trivia contains any newlines.
  var containsNewlines: Bool {
    return contains(where: {
      if case .newlines = $0 { return true }
      return false
    })
  }

  /// Returns `true` if this trivia contains any spaces.
  var containsSpaces: Bool {
    return contains(where: {
      if case .spaces = $0 { return true }
      if case .tabs = $0 { return true }
      return false
    })
  }
}
