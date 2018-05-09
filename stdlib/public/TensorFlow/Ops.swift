//===-- Ops.swift ------------------------------------------*- swift -*-===//
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
//
// This file contains core Tensor op definitions.
//
//===----------------------------------------------------------------------===//


//===----------------------------------------------------------------------===//
// Ops and Convenience Methods
//===----------------------------------------------------------------------===//
//
// The majority of the Tensor API is implemented in terms of 'ops' that are
// partitioned out to the TensorFlow graph when the compiler runs.  These
// ops are intentially designed to reflect TensorFlow ops, but provide nicer
// Swift syntax for accessing them.  In addition to the core ops themselves,
// we also define some helper function wrappers, e.g. to make things symmetric
// and generally feel nice to use.
//
// The ops themselves are defined by the primitive #tfop(...) syntax, here are
// some examples:
//     result = #tfop("Add", "tt:t", lhs, rhs)
//     result = #tfop("Const", "dc:t", Float.self, 4.0)
//
// The first two parameters to this syntax are the TensorFlow op name as a
// string, and then a constraint string - which specifies information about the
// operands and result type of the op.  The inputs are specified as additional
// arguments that follow.
//
// The constraint string is specified as two colon separated lists:
// "<OPERANDS>:<RESULTS>".  Here are the codes that are recognized for operands
// so far:
//
//    t: the next operand is a TensorHandle, and is an "input" to the TF node.
//    d: the next operand is a metatype value, and is added as a 'dtype'
//       attribute to the TF node. [TODO: Use param label to genericize name].
//    c: the next operand is a standard library integer or FP type.  We should
//       pass the value(s) as the 'value' attribute.  [TODO: Use param label to
//       genericize to names other than 'value'].
//
// The codes for the results are currently:
//
//    t: the result is a TensorHandle<T>, where the T is the same type as one
//       of the tensor input operands, or the type of the last dtype specified.
//    t<type>: the result is a TensorHandle<T>, where T is written out manually
//       using the same type names that TensorFlow ops use.
//


// Python PEP 465 makes a compelling argument that matrix multiplication should
// not be spelled with the standard * operator, so we need a new one.  We'll use
// this operator, though it is defensible to use a variety of other ones as well.
infix operator ⊗ : MultiplicationPrecedence

// TODO:
// - Unify Tensor and RankedTensor ops with protocol mechanism.
// - Consider explicit broadcasting for elementwise binary ops when
//   scalarization and rank getter are implemented.
//

/// Arithmetic Operators.
extension Tensor /*: Numeric*/ where Unit : Numeric {
  @_inlineable
  // @differentiable(gradient: _adjointAdd(_:_:primal:seed:))
  public static func +(lhs: Tensor, rhs: Tensor) -> Tensor {
    return Tensor(#tfop("Add", "tt:t", lhs.handle, rhs.handle))
  }

  @_inlineable
  // @differentiable(gradient: _adjointSubtract(_:_:primal:seed:))
  public static func -(lhs: Tensor, rhs: Tensor) -> Tensor {
    return Tensor(#tfop("Sub", "tt:t", lhs.handle, rhs.handle))
  }

  @_inlineable
  // @differentiable(gradient: _adjointMultiply(_:_:primal:seed:))
  public static func *(lhs: Tensor, rhs: Tensor) -> Tensor {
    return Tensor(#tfop("Mul", "tt:t", lhs.handle, rhs.handle))
  }
}

public extension Tensor where Unit : Numeric {
  @_inlineable
  // @differentiable(gradient: _adjointAdd(_:_:primal:seed:))
  static func +(lhs: Tensor, rhs: Unit) -> Tensor {
    return lhs + Tensor(rhs)
  }

  @_inlineable
  // @differentiable(gradient: _adjointAdd(_:_:primal:seed:))
  static func +(lhs: Unit, rhs: Tensor) -> Tensor {
    return Tensor(lhs) + rhs
  }

  @_inlineable
  static func +=(lhs: inout Tensor, rhs: Tensor) {
    lhs = lhs + rhs
  }

  @_inlineable
  // @differentiable(gradient: _adjointNegate(_:primal:seed:))
  static prefix func -(rhs: Tensor) -> Tensor {
    return Tensor(#tfop("Neg", "t:t", rhs.handle))
  }

  @_inlineable
  static func -(lhs: Tensor, rhs: Unit) -> Tensor {
    return lhs - Tensor(rhs)
  }

  @_inlineable
  static func -(lhs: Unit, rhs: Tensor) -> Tensor {
    return Tensor(lhs) - rhs
  }

  @_inlineable
  static func -=(lhs: inout Tensor, rhs: Tensor) {
    lhs = lhs - rhs
  }

  @_inlineable
  static func -=(lhs: inout Tensor, rhs: Unit) {
    lhs = lhs - rhs
  }

  @_inlineable
  static func *(lhs: Unit, rhs: Tensor) -> Tensor {
    return Tensor(lhs) * rhs
  }

  @_inlineable
  static func *(lhs: Tensor, rhs: Unit) -> Tensor {
    return lhs * Tensor(rhs)
  }

  @_inlineable
  static func /(lhs: Tensor, rhs: Tensor) -> Tensor {
    return Tensor(#tfop("Div", "tt:t", lhs.handle, rhs.handle))
  }

  @_inlineable
  static func /(lhs: Tensor, rhs: Unit) -> Tensor {
    return lhs / Tensor(rhs)
  }

  @_inlineable
  static func /(lhs: Unit, rhs: Tensor) -> Tensor {
    return Tensor(lhs) / rhs
  }

  @_inlineable
  static func /=(lhs: inout Tensor, rhs: Tensor) {
    lhs = lhs / rhs
  }

  @_inlineable
  static func /=(lhs: inout Tensor, rhs: Unit) {
    lhs = lhs / rhs
  }

  /// Matrix multiplication
  @_inlineable
  func dot(_ other: Tensor) -> Tensor {
    return Tensor(#tfop("MatMul", "tt:t", self.handle, other.handle))
  }

  @_inlineable
  static func ⊗ (lhs: Tensor, rhs: Tensor) -> Tensor {
    return lhs.dot(rhs)
  }

  @_inlineable
  static func ⊗ (lhs: Unit, rhs: Tensor) -> Tensor {
    return Tensor(lhs) ⊗ rhs
  }

  @_inlineable
  static func ⊗ (lhs: Tensor, rhs: Unit) -> Tensor {
    return lhs ⊗ Tensor(rhs)
  }

  @inline(never) // make @_inlinable when implemented.
  func mean() -> Unit {
    // FIXME: Implement!
    fatalError("FIXME: implement reduceMean")
  }

  @inline(never) // make @_inlinable when implemented.
  func reduceMean(
    alongAxes axes: Int...,
    keepingDimensions: Bool = false
  ) -> Tensor {
    fatalError("FIXME: implement max axis")
  }

  @inline(never) // make @_inlinable when implemented.
  func min() -> Unit {
    fatalError("FIXME: implement min")
  }

  @inline(never) // make @_inlinable when implemented.
  func reduceMin(
    alongAxes axes: Int...,
    keepingDimensions: Bool = false
  ) -> Tensor {
    fatalError("FIXME: implement max axis")
  }

  @inline(never) // make @_inlinable when implemented.
  func max() -> Unit {
    fatalError("FIXME: implement max")
  }

  @inline(never) // make @_inlinable when implemented.
  func reduceMax(
    alongAxes axes: Int...,
    keepingDimensions: Bool = false
  ) -> Tensor {
    fatalError("FIXME: implement max axis")
  }

  // Sum entire tensor to produce a scalar value.
  @inline(never) // make @_inlinable when implemented.
  func sum() -> Unit {
    fatalError("FIXME: implement sum")
  }

  @inline(never) // make @_inlinable when implemented.
  func reduceSum(
    alongAxes axes: Int...,
    keepingDimensions: Bool = false
  ) -> Tensor {
    fatalError("FIXME: implement max axis")
  }

  @inline(never) // make @_inlinable when implemented.
  func argmax() -> Int {
    fatalError("FIXME: implement argmax")
  }

  @inline(never) // make @_inlinable when implemented.
  func argmin() -> Int {
    fatalError("FIXME: implement argmin")
  }

  @_inlineable
  func squared() -> Tensor {
    return Tensor(#tfop("Square", "t:t", handle))
  }
}

public extension Tensor where Unit : Comparable {
  @_inlineable
  static func < (lhs: Tensor, rhs: Tensor) -> Tensor<Bool> {
    return Tensor<Bool>(#tfop("Less", "tt:t<bool>", lhs.handle, rhs.handle))
  }

  @_inlineable
  static func < (lhs: Tensor, rhs: Unit) -> Tensor<Bool> {
    return lhs < Tensor(rhs)
  }

  @_inlineable
  static func < (lhs: Unit, rhs: Tensor) -> Tensor<Bool> {
    return Tensor(lhs) < rhs
  }

  @_inlineable
  static func <= (lhs: Tensor, rhs: Tensor) -> Tensor<Bool> {
    return Tensor<Bool>(#tfop("LessEqual", "tt:t<bool>",
                        lhs.handle, rhs.handle))
  }

  @_inlineable
  static func <= (lhs: Tensor, rhs: Unit) -> Tensor<Bool> {
    return lhs <= Tensor(rhs)
  }

  @_inlineable
  static func <= (lhs: Unit, rhs: Tensor) -> Tensor<Bool> {
    return Tensor(lhs) <= rhs
  }

  @_inlineable
  static func > (lhs: Tensor, rhs: Tensor) -> Tensor<Bool> {
    return Tensor<Bool>(#tfop("Greater", "tt:t<bool>", lhs.handle, rhs.handle))
  }

  @_inlineable
  static func > (lhs: Tensor, rhs: Unit) -> Tensor<Bool> {
    return lhs > Tensor(rhs)
  }

  @_inlineable
  static func > (lhs: Unit, rhs: Tensor) -> Tensor<Bool> {
    return Tensor(lhs) > rhs
  }

  @_inlineable
  static func >= (lhs: Tensor, rhs: Tensor) -> Tensor<Bool> {
    return Tensor<Bool>(#tfop("GreaterEqual", "tt:t<bool>",
                       lhs.handle, rhs.handle))
  }

  @_inlineable
  static func >= (lhs: Tensor, rhs: Unit) -> Tensor<Bool> {
    return lhs >= Tensor(rhs)
  }

  @_inlineable
  static func >= (lhs: Unit, rhs: Tensor) -> Tensor<Bool> {
    return Tensor(lhs) >= rhs
  }
}

public extension Tensor where Unit : Equatable {
  @_inlineable
  static func == (lhs: Tensor, rhs: Tensor) -> Tensor<Bool> {
    return Tensor<Bool>(#tfop("Equal", "tt:t<bool>", lhs.handle, rhs.handle))
  }

  @_inlineable
  static func == (lhs: Tensor, rhs: Unit) -> Tensor<Bool> {
    return lhs == Tensor(rhs)
  }

  @_inlineable
  static func == (lhs: Unit, rhs: Tensor) -> Tensor<Bool> {
    return Tensor(lhs) == rhs
  }
}

/// Transposition and concatenation
public extension Tensor {
  @_inlineable
  var transpose: Tensor {
    return Tensor(#tfop("Transpose", "t:t", handle))
  }

  @inline(never) // make @_inlinable when implemented.
  func concatenated(with other: Tensor) -> Tensor {
    fatalError("FIXME: implement concatenated(with:)")
  }
}

@_inlineable
public func abs<Unit: Numeric>(
  _ x: Tensor<Unit>
) -> Tensor<Unit> {
  return Tensor(#tfop("Abs", "t:t", x.handle))
}

@_inlineable
// @differentiable(gradient: _adjointLog(_:primal:seed:))
public func log<Unit: FloatingPoint>(
  _ x: Tensor<Unit>
) -> Tensor<Unit> {
  return Tensor(#tfop("Log", "t:t", x.handle))
}

@_inlineable
// @differentiable(gradient: _adjointSin(_:primal:seed:))
public func sin<Unit: FloatingPoint>(
  _ x: Tensor<Unit>
) -> Tensor<Unit> {
  return Tensor(#tfop("Sin", "t:t", x.handle))
}

@_inlineable
// @differentiable(gradient: _adjointCos(_:primal:seed:))
public func cos<Unit: FloatingPoint>(
  _ x: Tensor<Unit>
) -> Tensor<Unit> {
  return Tensor(#tfop("Cos", "t:t", x.handle))
}

@_inlineable
// @differentiable(gradient: _adjointTan(_:primal:seed:))
public func tan<Unit: FloatingPoint>(
  _ x: Tensor<Unit>
) -> Tensor<Unit> {
  return Tensor(#tfop("Tan", "t:t", x.handle))
}

@_inlineable
// @differentiable(gradient: _adjointSinh(_:primal:seed:))
public func sinh<Unit: FloatingPoint>(
  _ x: Tensor<Unit>
) -> Tensor<Unit> {
  return Tensor(#tfop("Sinh", "t:t", x.handle))
}

@_inlineable
// @differentiable(gradient: _adjointCosh(_:primal:seed:))
public func cosh<Unit: FloatingPoint>(
  _ x: Tensor<Unit>
) -> Tensor<Unit> {
  return Tensor(#tfop("Cosh", "t:t", x.handle))
}

@_inlineable
// @differentiable(gradient: _adjointTanh(_:primal:seed:))
public func tanh<Unit: FloatingPoint>(
  _ x: Tensor<Unit>
) -> Tensor<Unit> {
  return Tensor(#tfop("Tanh", "t:t", x.handle))
}

@_inlineable
public func exp<Unit: FloatingPoint>(
  _ x: Tensor<Unit>
) -> Tensor<Unit> {
  return Tensor(#tfop("Exp", "t:t", x.handle))
}

@_inlineable
// @differentiable(gradient: _adjointPow(_:_:primal:seed:))
public func pow<Unit : Numeric>(
  _ lhs: Tensor<Unit>, _ rhs: Tensor<Unit>
) -> Tensor<Unit> {
  return Tensor(#tfop("Pow", "tt:t", lhs.handle, rhs.handle))
}

@_inlineable
public func pow<Unit : Numeric>(
  _ lhs: Unit, _ rhs: Tensor<Unit>
) -> Tensor<Unit> {
  return pow(Tensor(lhs), rhs)
}

@_inlineable
public func pow<Unit : Numeric>(
  _ lhs: Tensor<Unit>, _ rhs: Unit
) -> Tensor<Unit> {
  return pow(lhs, Tensor(rhs))
}

@_inlineable
// @differentiable(gradient: _adjointMin(_:_:primal:seed:))
public func min<Unit : Numeric & Comparable>(
  _ lhs: Tensor<Unit>, _ rhs: Tensor<Unit>
) -> Tensor<Unit> {
  return Tensor(#tfop("Min", "tt:t", lhs.handle, rhs.handle))
}

@_inlineable
public func min<Unit : Numeric & Comparable>(
  _ lhs: Unit, _ rhs: Tensor<Unit>
) -> Tensor<Unit> {
  return min(Tensor(lhs), rhs)
}

@_inlineable
public func min<Unit : Numeric & Comparable>(
  _ lhs: Tensor<Unit>, _ rhs: Unit
) -> Tensor<Unit> {
  return min(lhs, Tensor(rhs))
}

@_inlineable
// @differentiable(gradient: _adjointMax(_:_:primal:seed:))
public func max<Unit : Numeric & Comparable>(
  _ lhs: Tensor<Unit>, _ rhs: Tensor<Unit>
) -> Tensor<Unit> {
  return Tensor(#tfop("Max", "tt:t", lhs.handle, rhs.handle))
}

@_inlineable
public func max<Unit : Numeric & Comparable>(
  _ lhs: Unit, _ rhs: Tensor<Unit>
) -> Tensor<Unit> {
  return max(Tensor(lhs), rhs)
}

@_inlineable
public func max<Unit : Numeric & Comparable>(
  _ lhs: Tensor<Unit>, _ rhs: Unit
) -> Tensor<Unit> {
  return max(lhs, Tensor(rhs))
}

public extension Tensor where Unit == Bool {
  @inline(never) // Change to @_inlineable when implemented
  public func selecting<T>(_ left: Tensor<T>, _ right: Tensor<T>) -> Tensor<T> {
    // FIXME(clattner?): Add support for 't<bool>' in arguments.
    // return Tensor(#tfop("Select", "t<bool>tt:t",
    //               handle, left.handle, right.handle))
    fatalError("Unimplemented")
  }

  @_inlineable
  public func selecting<T>(_ left: T, _ right: Tensor<T>) -> Tensor<T> {
    return selecting(Tensor<T>(left), right)
  }

  @_inlineable
  public func selecting<T>(_ left: Tensor<T>, _ right: T) -> Tensor<T> {
    return selecting(left, Tensor<T>(right))
  }
}

public extension Tensor2D where Unit : Numeric {
  // Sum tensor along one axis, producing a Tensor1D.
  @_inlineable
  func reduceSum(alongAxis axis: Int) -> Tensor1D<Unit> {
    return Tensor1D<Unit>(underlying:
      underlyingTensor.reduceSum(alongAxes: axis))
  }

  @_inlineable
  func reduceMax(alongAxis axis: Int) -> Tensor1D<Unit> {
    return Tensor1D<Unit>(underlying:
      underlyingTensor.reduceMax(alongAxes: axis))
  }

  @_inlineable
  func reduceMin(alongAxis axis: Int) -> Tensor1D<Unit> {
    return Tensor1D<Unit>(underlying:
      underlyingTensor.reduceMin(alongAxes: axis))
  }

  @_inlineable
  func reduceMean(alongAxis axis: Int) -> Tensor1D<Unit> {
    return Tensor1D<Unit>(underlying:
      underlyingTensor.reduceMean(alongAxes: axis))
  }
}

public extension Tensor2D where Unit : Numeric {
  @_inlineable
  static func ⊗ (
    lhs: Tensor1D<Unit>, rhs: Tensor2D<Unit>
  ) -> Tensor1D<Unit> {
    return Tensor1D(underlying: lhs.underlyingTensor.dot(rhs.underlyingTensor))
  }
}

public extension Tensor {
  @_inlineable
  var shapeTensor: Tensor<Int32> {
    return Tensor<Int32>(#tfop("Shape", "t:t<int32>", handle))
  }

  @_inlineable
  var rankTensor: Tensor<Int32> {
    return Tensor<Int32>(#tfop("Rank", "t:t<int32>", handle))
  }

  @_inlineable
  var unitCountTensor: Tensor<Int32> {
    return Tensor<Int32>(#tfop("Size", "t:t<int32>", handle))
  }
}

/// Slicing
public extension Tensor {
  /// Returns a subdimensional tensor at the specified list of indices.
  /// - Todo: If possible, this should be defined as an op, to be run on the
  /// accelerator.
  subscript(indices: Int...) -> Tensor {
    fatalError("FIXME: implement subscript to tensor")
  }

  // Slicing out a range of subdimensional tensors.
  // TODO: begin/end are vectors in general.
  // tfop_slice(tensor, begin, end) -> tensor
  subscript(bounds: Range<Int>) -> Tensor {
    fatalError("FIXME: implement subscript to tensor")
  }
}
