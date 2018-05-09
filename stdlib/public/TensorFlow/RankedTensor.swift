//===-- RankedTensor.swift ------------------------------------*- swift -*-===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2017 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

infix operator ⊗ : MultiplicationPrecedence

/// RankedTensor - This is the common protocol shared between the Tensor[12345]D
/// types defined below, defining their common basic API.  This allows reuse
/// of the implementation logic for these types (which just wrap Tensor anyway)
/// and allow writing rank-generic code over the TensorXD types.
public protocol RankedTensor {
  associatedtype Unit : AccelerableTensorUnit
  associatedtype Shape

  /// Convert from a rank-erased Tensor to the specified RankedTensor.  This
  /// fails when the Tensor has the wrong rank.
  init?(_ other: Tensor<Unit>)

  /// Convert from a rank-erased Tensor to the specified RankedTensor when there
  /// is some static information that tells us that it is of the correct rank
  /// already.
  init(identicallyRanked other: Tensor<Unit>)

  /// Tensor of same rank, but Bool element type.
  associatedtype BoolTensor : RankedTensor where BoolTensor.Unit == Bool

  /// Returns the rank of the Tensor - the number of dimensions it has.
  static var rank: Int { get }

  /// Returns the shape of the Tensor
  var shape: Shape { get }

  /// Returns the rank erased Tensor held by the RankedTensor.
  var underlyingTensor: Tensor<Unit> { get }
}

/// Array initializers
public extension RankedTensor {
  /// Convert from a ShapedArray to the specified RankedTensor. This fails
  /// when the ShapedArray has the wrong rank.
  init?(_ other: ShapedArray<Unit>) {
    self.init(Tensor(other))
  }

  /// Convert from a ShapedArray to the specified RankedTensor when there is
  /// some static information that tells us that it is of the correct rank
  /// already.
  init(identicallyRanked other: ShapedArray<Unit>) {
    self.init(identicallyRanked: Tensor(other))
  }
}

/// Memory transfer markers
/// TODO: Remove when send/receive semantics gets revisited.
public extension RankedTensor {
  /// Indicate that this tensor is being moved to the accelerator.
  @_inlineable
  func toDevice() -> Self {
    return Self(identicallyRanked: underlyingTensor.toDevice())
  }

  /// Indicate that this tensor is being moved to the host.
  @_inlineable
  func toHost() -> Self {
    return Self(identicallyRanked: underlyingTensor.toHost())
  }
}

/// Common properties
public extension RankedTensor {
  var rank: Int {
    return Self.rank
  }
}

/// Slicing
public extension RankedTensor {
  @_inlineable
  subscript(bounds: Range<Int>) -> Self {
    return Self(identicallyRanked: underlyingTensor[bounds])
  }
}

// Each of these extensions on RankedTensor adds APIs to each of the specific
// ranks, implemented in terms of the underlying untyped Tensor APIs.

/// Arithmetic operators
public extension RankedTensor where Unit : Numeric {
  @_inlineable
  static func +(lhs: Self, rhs: Self) -> Self {
    return Self(identicallyRanked: lhs.underlyingTensor + rhs.underlyingTensor)
  }

  @_inlineable
  static func +=(lhs: inout Self, rhs: Self) {
    lhs = lhs + rhs
  }

  @_inlineable
  static func +(lhs: Self, rhs: Unit) -> Self {
    return Self(identicallyRanked: lhs.underlyingTensor + rhs)
  }

  @_inlineable
  static func +(lhs: Unit, rhs: Self) -> Self {
    return Self(identicallyRanked: lhs + rhs.underlyingTensor)
  }

  @_inlineable
  static prefix func -(rhs: Self) -> Self {
    return Self(identicallyRanked: -rhs.underlyingTensor)
  }

  @_inlineable
  static func -(lhs: Self, rhs: Self) -> Self {
    return Self(identicallyRanked: lhs.underlyingTensor - rhs.underlyingTensor)
  }

  @_inlineable
  static func -(lhs: Self, rhs: Unit) -> Self {
    return Self(identicallyRanked: lhs.underlyingTensor - rhs)
  }

  @_inlineable
  static func -(lhs: Unit, rhs: Self) -> Self {
    return Self(identicallyRanked: lhs - rhs.underlyingTensor)
  }

  @_inlineable
  static func -=(lhs: inout Self, rhs: Self) {
    lhs = lhs - rhs
  }

  @_inlineable
  static func /(lhs: Self, rhs: Self) -> Self {
    return Self(identicallyRanked: lhs.underlyingTensor / rhs.underlyingTensor)
  }

  @_inlineable
  static func /(lhs: Self, rhs: Unit) -> Self {
    return Self(identicallyRanked: lhs.underlyingTensor / rhs)
  }

  @_inlineable
  static func /(lhs: Unit, rhs: Self) -> Self {
    return Self(identicallyRanked: lhs / rhs.underlyingTensor)
  }

  @_inlineable
  static func *(lhs: Self, rhs: Self) -> Self {
    return Self(identicallyRanked: lhs.underlyingTensor * rhs.underlyingTensor)
  }

  @_inlineable
  static func *(lhs: Unit, rhs: Self) -> Self {
    return Self(identicallyRanked: lhs * rhs.underlyingTensor)
  }

  @_inlineable
  static func *(lhs: Self, rhs: Unit) -> Self {
    return Self(identicallyRanked: lhs.underlyingTensor * rhs)
  }

  @_inlineable
  func dot(_ other: Self) -> Self {
    return Self(identicallyRanked: underlyingTensor.dot(other.underlyingTensor))
  }

  @_inlineable
  static func ⊗(lhs: Self, rhs: Self) -> Self {
    return lhs.dot(rhs)
  }

  @_inlineable
  func mean() -> Unit {
    return underlyingTensor.mean()
  }

  @_inlineable
  func min() -> Unit {
    return underlyingTensor.min()
  }

  @_inlineable
  func max() -> Unit {
    return underlyingTensor.max()
  }

  @_inlineable
  func argmax() -> Int {
    return underlyingTensor.argmax()
  }

  @_inlineable
  func sum() -> Unit {
    return underlyingTensor.sum()
  }

  @_inlineable
  func square() -> Self {
    return transposed().dot(self)
  }
}

public extension RankedTensor where Unit : Comparable {
  @_inlineable
  static func < (lhs: Self, rhs: Unit) -> BoolTensor {
    return BoolTensor(identicallyRanked: lhs.underlyingTensor < rhs)
  }
}

public extension RankedTensor where Unit : Equatable {
  @_inlineable
  static func == (lhs: Self, rhs: Unit) -> BoolTensor {
    return BoolTensor(identicallyRanked: lhs.underlyingTensor == rhs)
  }
}

/// Transposition and concatenation
public extension RankedTensor {
  @_inlineable
  func transposed() -> Self {
    return Self(identicallyRanked: underlyingTensor.transposed())
  }
}

/// Make "print(someTensor)" print a pretty form of the tensor.
extension RankedTensor {
  public var description: String {
    return underlyingTensor.description
  }
}

/// Make Tensors show up nicely in the Xcode Playground results sidebar.
extension RankedTensor {
  public var customPlaygroundQuickLook: PlaygroundQuickLook {
    return .text(description)
  }
}
