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
// This file contains definitions of tensor operations common to TensorProtocol.
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
//     result = #tfop("Add", lhs, rhs)
//     result = #tfop("Const", dtype: Float.self, value$tensor: 4.0)
//
// The first parameter to this syntax is the TensorFlow op name as a string.
// After that, the inputs and attributes are specified as additional
// arguments that follow.  Tensor and scalar inputs are specified first, without
// keyword arguments, then attributes are specified next with their name as the
// keyword argument.
//

// Python PEP 465 makes a compelling argument that matrix multiplication should
// not be spelled with the standard * operator, so we need a new one.  We'll use
// this operator, though it is defensible to use a variety of other ones as well.
infix operator ⊗ : MultiplicationPrecedence

// TODO:
// - Consider explicit broadcasting for elementwise binary ops when
//   scalarization and rank getter are implemented.

extension Tensor : TensorProtocol {
  public typealias BoolTensor = Tensor<Bool>
}

extension Tensor1D : TensorProtocol {
  public typealias BoolTensor = Tensor1D<Bool>
}

extension Tensor2D : TensorProtocol {
  public typealias BoolTensor = Tensor2D<Bool>
}

extension Tensor3D : TensorProtocol {
  public typealias BoolTensor = Tensor3D<Bool>
}

extension Tensor4D : TensorProtocol {
  public typealias BoolTensor = Tensor4D<Bool>
}

//===----------------------------------------------------------------------===//
// Elementwise binary arithmetics
//===----------------------------------------------------------------------===//

extension TensorProtocol /*: Numeric*/ where Scalar : Numeric {
  @_inlineable @inline(__always)
  // @differentiable(gradient: _adjointAdd(_:_:primal:seed:))
  public static func +(lhs: Self, rhs: Self) -> Self {
    return #tfop("Add", lhs, rhs)
  }

  @_inlineable @inline(__always)
  // @differentiable(gradient: _adjointSubtract(_:_:primal:seed:))
  public static func -(lhs: Self, rhs: Self) -> Self {
    return #tfop("Sub", lhs, rhs)
  }

  @_inlineable @inline(__always)
  // @differentiable(gradient: _adjointMultiply(_:_:primal:seed:))
  public static func *(lhs: Self, rhs: Self) -> Self {
    return #tfop("Mul", lhs, rhs)
  }
}

public extension TensorProtocol where Scalar : Numeric {
  @_inlineable @inline(__always)
  // @differentiable(gradient: _adjointAdd(_:_:primal:seed:))
  static func +(lhs: Scalar, rhs: Self) -> Self {
    return #tfop("Add", _TFMakeScalarTensor(lhs), rhs)
  }

  @_inlineable @inline(__always)
  // @differentiable(gradient: _adjointAdd(_:_:primal:seed:))
  static func +(lhs: Self, rhs: Scalar) -> Self {
    return #tfop("Add", lhs, _TFMakeScalarTensor(rhs))
  }

  @_inlineable @inline(__always)
  static func +=(lhs: inout Self, rhs: Self) {
    lhs = lhs + rhs
  }

  @_inlineable @inline(__always)
  static func +=(lhs: inout Self, rhs: Scalar) {
    lhs = lhs + rhs
  }

  @_inlineable @inline(__always)
  // @differentiable(gradient: _adjointNegate(_:primal:seed:))
  static prefix func -(rhs: Self) -> Self {
    return #tfop("Neg", rhs)
  }

  @_inlineable @inline(__always)
  static func -(lhs: Scalar, rhs: Self) -> Self {
    return #tfop("Sub", _TFMakeScalarTensor(lhs), rhs)
  }

  @_inlineable @inline(__always)
  static func -(lhs: Self, rhs: Scalar) -> Self {
    return #tfop("Sub", lhs, _TFMakeScalarTensor(rhs))
  }

  @_inlineable @inline(__always)
  static func -=(lhs: inout Self, rhs: Self) {
    lhs = lhs - rhs
  }

  @_inlineable @inline(__always)
  static func -=(lhs: inout Self, rhs: Scalar) {
    lhs = lhs - rhs
  }

  @_inlineable @inline(__always)
  static func *(lhs: Scalar, rhs: Self) -> Self {
    return #tfop("Mul", _TFMakeScalarTensor(lhs), rhs)
  }

  @_inlineable @inline(__always)
  static func *(lhs: Self, rhs: Scalar) -> Self {
    return #tfop("Mul", lhs, _TFMakeScalarTensor(rhs))
  }

  @_inlineable @inline(__always)
  static func *=(lhs: inout Self, rhs: Self) {
    lhs = lhs * rhs
  }

  @_inlineable @inline(__always)
  static func *=(lhs: inout Self, rhs: Scalar) {
    lhs = lhs * rhs
  }

  @_inlineable @inline(__always)
  static func /(lhs: Self, rhs: Self) -> Self {
    return #tfop("Div", lhs, rhs)
  }

  @_inlineable @inline(__always)

  static func /(lhs: Scalar, rhs: Self) -> Self {
    return #tfop("Div", _TFMakeScalarTensor(lhs), rhs)
  }

  @_inlineable @inline(__always)
  static func /(lhs: Self, rhs: Scalar) -> Self {
    return #tfop("Div", lhs, _TFMakeScalarTensor(rhs))
  }

  @_inlineable @inline(__always)
  static func /=(lhs: inout Self, rhs: Self) {
    lhs = lhs / rhs
  }

  @_inlineable @inline(__always)
  static func /=(lhs: inout Self, rhs: Scalar) {
    lhs = lhs / rhs
  }

  @_inlineable @inline(__always)
  static func %(lhs: Self, rhs: Self) -> Self {
    return #tfop("Mod", lhs, rhs)
  }

  @_inlineable @inline(__always)
  static func %(lhs: Self, rhs: Scalar) -> Self {
    return #tfop("Mod", lhs, _TFMakeScalarTensor(rhs))
  }

  @_inlineable @inline(__always)
  static func %(lhs: Scalar, rhs: Self) -> Self {
    return #tfop("Mod", _TFMakeScalarTensor(lhs), rhs)
  }

  @_inlineable @inline(__always)
  static func %=(lhs: inout Self, rhs: Self) {
    lhs = lhs % rhs
  }

  @_inlineable @inline(__always)
  static func %=(lhs: inout Self, rhs: Scalar) {
    lhs = lhs % rhs
  }
}

//===----------------------------------------------------------------------===//
// Linear algebra
//===----------------------------------------------------------------------===//

public extension TensorProtocol where Scalar : Numeric {
  @_inlineable @inline(__always)
  func dot(_ other: Self) -> Self {
    return #tfop("MatMul", self, other)
  }

  @_inlineable @inline(__always)
  static func ⊗ (lhs: Self, rhs: Self) -> Self {
    return lhs.dot(rhs)
  }
}

//===----------------------------------------------------------------------===//
// Elementwise binary comparison
//===----------------------------------------------------------------------===//

public extension TensorProtocol where Scalar : Comparable {
  @_inlineable @inline(__always)
  static func < (lhs: Self, rhs: Self) -> BoolTensor {
    return #tfop("Less", lhs, rhs)
  }

  @_inlineable @inline(__always)
  static func < (lhs: Self, rhs: Scalar) -> BoolTensor {
    return #tfop("Less", lhs, _TFMakeScalarTensor(rhs))
  }

  @_inlineable @inline(__always)
  static func < (lhs: Scalar, rhs: Self) -> BoolTensor {
    return #tfop("Less", _TFMakeScalarTensor(lhs), rhs)
  }

  @_inlineable @inline(__always)
  static func <= (lhs: Self, rhs: Self) -> BoolTensor {
    return #tfop("LessEqual", lhs, rhs)
  }

  @_inlineable @inline(__always)
  static func <= (lhs: Self, rhs: Scalar) -> BoolTensor {
    return #tfop("LessEqual", lhs, _TFMakeScalarTensor(rhs))
  }

  @_inlineable @inline(__always)
  static func <= (lhs: Scalar, rhs: Self) -> BoolTensor {
    return #tfop("LessEqual", _TFMakeScalarTensor(lhs), rhs)
  }

  @_inlineable @inline(__always)
  static func > (lhs: Self, rhs: Self) -> BoolTensor {
    return #tfop("Greater", lhs, rhs)
  }

  @_inlineable @inline(__always)
  static func > (lhs: Self, rhs: Scalar) -> BoolTensor {
    return #tfop("Greater", lhs, _TFMakeScalarTensor(rhs))
  }

  @_inlineable @inline(__always)
  static func > (lhs: Scalar, rhs: Self) -> BoolTensor {
    return #tfop("Greater", _TFMakeScalarTensor(lhs), rhs)
  }

  @_inlineable @inline(__always)
  static func >= (lhs: Self, rhs: Self) -> BoolTensor {
    return #tfop("GreaterEqual", lhs, rhs)
  }

  @_inlineable @inline(__always)
  static func >= (lhs: Self, rhs: Scalar) -> BoolTensor {
    return #tfop("GreaterEqual", lhs, _TFMakeScalarTensor(rhs))
  }

  @_inlineable @inline(__always)
  static func >= (lhs: Scalar, rhs: Self) -> BoolTensor {
    return #tfop("GreaterEqual", _TFMakeScalarTensor(lhs), rhs)
  }
}

public extension TensorProtocol where Scalar : Equatable {
  @_inlineable @inline(__always)
  static func == (lhs: Self, rhs: Self) -> BoolTensor {
    return #tfop("Equal", lhs, rhs)
  }

  @_inlineable @inline(__always)
  static func == (lhs: Self, rhs: Scalar) -> BoolTensor {
    return #tfop("Equal", lhs, _TFMakeScalarTensor(rhs))
  }

  @_inlineable @inline(__always)
  static func == (lhs: Scalar, rhs: Self) -> BoolTensor {
    return #tfop("Equal", _TFMakeScalarTensor(lhs), rhs)
  }

  @_inlineable @inline(__always)
  static func != (lhs: Self, rhs: Self) -> BoolTensor {
    return #tfop("NotEqual", lhs, rhs)
  }

  @_inlineable @inline(__always)
  static func != (lhs: Self, rhs: Scalar) -> BoolTensor {
    return #tfop("NotEqual", lhs, _TFMakeScalarTensor(rhs))
  }

  @_inlineable @inline(__always)
  static func != (lhs: Scalar, rhs: Self) -> BoolTensor {
    return #tfop("NotEqual", _TFMakeScalarTensor(lhs), rhs)
  }
}

public extension TensorProtocol where Scalar == Bool {
  @_inlineable @inline(__always)
  static prefix func ! (x: Self) -> Self {
    return #tfop("LogicalNot", x)
  }

  @_inlineable @inline(__always)
  static func && (lhs: Self, rhs: Self) -> Self {
    return #tfop("LogicalAnd", lhs, rhs)
  }

  @_inlineable @inline(__always)
  static func && (lhs: Self, rhs: Scalar) -> Self {
    return #tfop("LogicalAnd", lhs, _TFMakeScalarTensor(rhs))
  }

  @_inlineable @inline(__always)
  static func && (lhs: Scalar, rhs: Self) -> Self {
    return #tfop("LogicalAnd", _TFMakeScalarTensor(lhs), rhs)
  }

  @_inlineable @inline(__always)
  static func || (lhs: Self, rhs: Self) -> Self {
    return #tfop("LogicalOr", lhs, rhs)
  }

  @_inlineable @inline(__always)
  static func || (lhs: Self, rhs: Scalar) -> Self {
    return #tfop("LogicalOr", lhs, _TFMakeScalarTensor(rhs))
  }

  @_inlineable @inline(__always)
  static func || (lhs: Scalar, rhs: Self) -> Self {
    return #tfop("LogicalOr", _TFMakeScalarTensor(lhs), rhs)
  }
}

//===----------------------------------------------------------------------===//
// Transforms
//===----------------------------------------------------------------------===//

public extension TensorProtocol {
  /// Returns a transposed tensor, with dimensions permuted in the specified
  /// order.
  @_inlineable @inline(__always)
  // @differentiable(
  //   withRespectTo: (self),
  //   gradient: _adjointTransposed(_:_:primal:seed:)
  // )
  func transposed(withPermutations permutations: Tensor<Int32>) -> Self {
    return #tfop("Transpose", handle, permutations, Tperm: Int32.self)
  }

  /// Returns a transposed tensor, with dimensions permuted in the specified
  /// order.
  @_inlineable @inline(__always)
  func transposed(withPermutations permutations: [Int32]) -> Self {
    return transposed(withPermutations: Tensor<Int32>(permutations))
  }

  /// Returns a transposed tensor, with dimensions permuted in the specified
  /// order.
  @_inlineable @inline(__always)
  func transposed(withPermutations permutations: Int32...) -> Self {
    return transposed(withPermutations: permutations)
  }

  /// Returns a transposed tensor, with dimensions permuted in reverse order.
  @_inlineable @inline(__always)
  func transposed() -> Self {
    let defaultPermutations = (rankTensor - 1) - Tensor<Int32>(
      rangeFrom: Tensor<Int32>(handle: _TFMakeScalarTensor(0)),
      to: rankTensor,
      stride: Tensor<Int32>(handle: _TFMakeScalarTensor(1))
    )
    return transposed(withPermutations: defaultPermutations)
  }
}

//===----------------------------------------------------------------------===//
// Elementwise basic math functions
//===----------------------------------------------------------------------===//

@_inlineable @inline(__always)
public func abs<Scalar: Numeric, T : TensorProtocol>(
  _ x: T
) -> T where T.Scalar == Scalar {
  return #tfop("Abs", x)
}

@_inlineable @inline(__always)
// @differentiable(gradient: _adjointLog(_:primal:seed:))
public func log<Scalar: FloatingPoint, T : TensorProtocol>(
  _ x: T
) -> T where T.Scalar == Scalar {
  return #tfop("Log", x)
}

@_inlineable @inline(__always)
// @differentiable(gradient: _adjointSin(_:primal:seed:))
public func sin<Scalar: FloatingPoint, T : TensorProtocol>(
  _ x: T
) -> T where T.Scalar == Scalar {
  return #tfop("Sin", x)
}

@_inlineable @inline(__always)
// @differentiable(gradient: _adjointCos(_:primal:seed:))
public func cos<Scalar: FloatingPoint, T : TensorProtocol>(
  _ x: T
) -> T where T.Scalar == Scalar {
  return #tfop("Cos", x)
}

@_inlineable @inline(__always)
// @differentiable(gradient: _adjointTan(_:primal:seed:))
public func tan<Scalar: FloatingPoint, T : TensorProtocol>(
  _ x: T
) -> T where T.Scalar == Scalar {
  return #tfop("Tan", x)
}

@_inlineable @inline(__always)
// @differentiable(gradient: _adjointSinh(_:primal:seed:))
public func sinh<Scalar: FloatingPoint, T : TensorProtocol>(
  _ x: T
) -> T where T.Scalar == Scalar {
  return #tfop("Sinh", x)
}

@_inlineable @inline(__always)
// @differentiable(gradient: _adjointCosh(_:primal:seed:))
public func cosh<Scalar: FloatingPoint, T : TensorProtocol>(
  _ x: T
) -> T where T.Scalar == Scalar {
  return #tfop("Cosh", x)
}

@_inlineable @inline(__always)
// @differentiable(gradient: _adjointTanh(_:primal:seed:))
public func tanh<Scalar: FloatingPoint, T : TensorProtocol>(
  _ x: T
) -> T where T.Scalar == Scalar {
  return #tfop("Tanh", x)
}

@_inlineable @inline(__always)
public func sqrt<Scalar: FloatingPoint, T : TensorProtocol>(
  _ x: T
) -> T where T.Scalar == Scalar {
  return #tfop("Sqrt", x)
}

@_inlineable @inline(__always)
public func exp<Scalar: FloatingPoint, T : TensorProtocol>(
  _ x: T
) -> T where T.Scalar == Scalar {
  return #tfop("Exp", x)
}

@_inlineable @inline(__always)
// @differentiable(gradient: _adjointPow(_:_:primal:seed:))
public func pow<Scalar : Numeric, T : TensorProtocol>(
  _ lhs: T, _ rhs: T
) -> T where T.Scalar == Scalar {
  return #tfop("Pow", lhs, rhs)
}

@_inlineable @inline(__always)
public func pow<Scalar : Numeric, T : TensorProtocol>(
  _ lhs: Scalar, _ rhs: T
) -> T where T.Scalar == Scalar {
  return pow(T(handle: _TFMakeScalarTensor(lhs)), rhs)
}

@_inlineable @inline(__always)
public func pow<Scalar : Numeric, T : TensorProtocol>(
  _ lhs: T, _ rhs: Scalar
) -> T where T.Scalar == Scalar {
  return pow(lhs, T(handle: _TFMakeScalarTensor(rhs)))
}

@_inlineable @inline(__always)
// @differentiable(gradient: _adjointMin(_:_:primal:seed:))
public func min<Scalar : Numeric & Comparable, T : TensorProtocol>(
  _ lhs: T, _ rhs: T
) -> T where T.Scalar == Scalar {
  return #tfop("Min", lhs, rhs)
}

@_inlineable @inline(__always)
public func min<Scalar : Numeric & Comparable, T : TensorProtocol>(
  _ lhs: Scalar, _ rhs: T
) -> T where T.Scalar == Scalar {
  return min(T(handle: _TFMakeScalarTensor(lhs)), rhs)
}

@_inlineable @inline(__always)
public func min<Scalar : Numeric & Comparable, T : TensorProtocol>(
  _ lhs: T, _ rhs: Scalar
) -> T where T.Scalar == Scalar {
  return min(lhs, T(handle: _TFMakeScalarTensor(rhs)))
}

@_inlineable @inline(__always)
// @differentiable(gradient: _adjointMax(_:_:primal:seed:))
public func max<Scalar : Numeric & Comparable, T : TensorProtocol>(
  _ lhs: T, _ rhs: T
) -> T where T.Scalar == Scalar {
  return #tfop("Max", lhs, rhs)
}

@_inlineable @inline(__always)
public func max<Scalar : Numeric & Comparable, T : TensorProtocol>(
  _ lhs: Scalar, _ rhs: T
) -> T where T.Scalar == Scalar {
  return max(T(handle: _TFMakeScalarTensor(lhs)), rhs)
}

@_inlineable @inline(__always)
public func max<Scalar : Numeric & Comparable, T : TensorProtocol>(
  _ lhs: T, _ rhs: Scalar
) -> T where T.Scalar == Scalar {
  return max(lhs, T(handle: _TFMakeScalarTensor(rhs)))
}

public extension TensorProtocol {
  @_inlineable @inline(__always)
  func squared() -> Self {
    return #tfop("Square", handle)
  }
}

//===----------------------------------------------------------------------===//
// Selection
//===----------------------------------------------------------------------===//

public extension TensorProtocol where Scalar == Bool {
  @_inlineable @inline(__always)
  public func selecting<U, T : TensorProtocol>(_ left: T, _ right: T) -> T
    where T.Scalar == U {
    return #tfop("Select", handle, left, right)
  }

  @_inlineable @inline(__always)
  public func selecting<U, T : TensorProtocol>(_ left: U, _ right: T) -> T
  where T.Scalar == U {
    return #tfop("Select", handle, _TFMakeScalarTensor(left), right)
  }

  @_inlineable @inline(__always)
  public func selecting<U, T : TensorProtocol>(_ left: T, _ right: U) -> T
    where T.Scalar == U {
    return #tfop("Select", handle, left, _TFMakeScalarTensor(right))
  }
}

//===----------------------------------------------------------------------===//
// Reduction
//===----------------------------------------------------------------------===//

public extension TensorProtocol {
  @_inlineable @inline(__always)
  func mean() -> Scalar {
    return _TFGetScalarOrDie(#tfop("Mean", handle,
                                   Tensor<Int32>([] as [Int32]).handle))
  }

  @_inlineable @inline(__always)
  func min() -> Scalar {
    return _TFGetScalarOrDie(#tfop("Min", handle,
                                   Tensor<Int32>([] as [Int32]).handle))
  }

  @_inlineable @inline(__always)
  func max() -> Scalar {
    return _TFGetScalarOrDie(#tfop("Max", handle,
                                   Tensor<Int32>([] as [Int32]).handle))
  }

  @_inlineable @inline(__always)
  func sum() -> Scalar {
    return _TFGetScalarOrDie(#tfop("Sum", handle,
                                   Tensor<Int32>([] as [Int32]).handle))
  }

  @inline(never) // make @_inlineable when implemented.
  func argmax() -> Int {
    fatalError("FIXME: implement argmax")
  }

  @inline(never) // make @_inlineable when implemented.
  func argmin() -> Int {
    fatalError("FIXME: implement argmin")
  }
}

public extension Tensor {
  @_inlineable @inline(__always)
  func mean(
    alongAxes axes: [Int32],
    keepingDimensions: Bool = false
  ) -> Tensor {
    return #tfop("Mean", handle, Tensor<Int32>(axes),
                 keep_dims: keepingDimensions, Tidx: Int32.self)
  }

  @_inlineable @inline(__always)
  func min(
    alongAxes axes: [Int32],
    keepingDimensions: Bool = false
  ) -> Tensor {
    return #tfop("Min", handle, Tensor<Int32>(axes),
                 keep_dims: keepingDimensions, Tidx: Int32.self)
  }

  @_inlineable @inline(__always)
  func max(
    alongAxes axes: [Int32],
    keepingDimensions: Bool = false
  ) -> Tensor {
    return Tensor<Scalar>(handle:
      #tfop("Max", handle, Tensor<Int32>(axes).handle,
            keep_dims: keepingDimensions, Tidx: Int32.self))
  }

  @_inlineable @inline(__always)
  func sum(
    alongAxes axes: [Int32],
    keepingDimensions: Bool = false
  ) -> Tensor {
    return #tfop("Sum", handle, Tensor<Int32>(axes),
                 keep_dims: keepingDimensions, Tidx: Int32.self)
  }
}

//===----------------------------------------------------------------------===//
// Tensor properties
//===----------------------------------------------------------------------===//

public extension TensorProtocol {
  @_inlineable
  var shapeTensor: Tensor<Int32> {
    @inline(__always)
    get {
      return #tfop("Shape", handle)
    }
  }

  @_inlineable
  var rankTensor: Tensor<Int32> {
    @inline(__always)
    get {
      return #tfop("Rank", handle)
    }
  }

  @_inlineable
  var scalarCountTensor: Tensor<Int32> {
    @inline(__always)
    get {
      return #tfop("Size", handle)
    }
  }
}


//===----------------------------------------------------------------------===//
// Indexing and slicing
//===----------------------------------------------------------------------===//

public extension Tensor {
  /// Access the element tensor specified by an index in the leading dimension.
  /// - Parameter index: index of the element tensor
  subscript(index: Int) -> Tensor {
    get {
      fatalError("FIXME: implement subscript to tensor")
    }
    set {
      fatalError("FIXME: implement subscript to tensor")
    }
  }

  /// Returns the subdimensional tensor at the specified list of indices.
  /// - Parameter indices: list of indices
  /// - TODO: If possible, this should be defined as an op, to be run on the
  /// accelerator.
  subscript(indices: Int...) -> Tensor {
    get {
      fatalError("FIXME: implement subscript to tensor")
    }
    set {
      fatalError("FIXME: implement subscript to tensor")
    }
  }

  /// Returns the subtensor defined by the specified bounds.
  /// - Parameter bounds: contiguous range of indices
  // TODO: begin/end are vectors in general.
  // tfop_slice(tensor, begin, end) -> tensor
  subscript(bounds: Range<Int>) -> Tensor {
    get {
      fatalError("FIXME: implement subscript to tensor")
    }
    set {
      fatalError("FIXME: implement subscript to tensor")
    }
  }
}

//===----------------------------------------------------------------------===//
// Convolution and pooling
//===----------------------------------------------------------------------===//

public enum Padding {
  case same, valid
}

internal extension Padding {
  @_inlineable
  @_versioned
  var cName: String {
    switch self {
    case .same: return "SAME"
    case .valid: return "VALID"
    }
  }
}

public extension Tensor where Scalar : FloatingPoint {
  @_inlineable @inline(__always)
  // @differentiable(
  //   withRespectTo: (self, .0),
  //   gradient: _adjointConvolve2D(input:filter:primal:seed:)
  // )
  func convolved2D(
    withFilter filter: Tensor,
    strides: [Int32],
    padding: Padding
  ) -> Tensor {
    return #tfop("Conv2D", handle, filter, strides: strides,
                 padding: padding.cName)
  }

  @_inlineable @inline(__always)
  // @differentiable(
  //   withRespectTo: (self),
  //   gradient:
  //     _adjointMaxPooled2D(input:kernelSize:strides:padding:primal:seed:)
  // )
  func maxPooled(
    kernelSize: Tensor<Int32>,
    strides: Tensor<Int32>,
    padding: Padding
  ) -> Tensor {
    return #tfop("MaxPoolV2", handle, Tensor<Int32>(kernelSize),
                 Tensor<Int32>(strides), padding: padding.cName)
  }

  @_inlineable @inline(__always)
  func maxPooled(
    kernelSize: [Int32],
    strides: [Int32],
    padding: Padding
  ) -> Tensor {
    return maxPooled(kernelSize: Tensor<Int32>(kernelSize),
                     strides: Tensor<Int32>(strides),
                     padding: padding)
  }

  @_inlineable @inline(__always)
  // @differentiable(
  //   withRespectTo: (self),
  //   gradient:
  //     _adjointAveragePooled2D(input:kernelSize:strides:padding:primal:seed:)
  // )
  func averagePooled(
    kernelSize: [Int32],
    strides: [Int32],
    padding: Padding
  ) -> Tensor {
    return #tfop("AvgPool", handle, ksize: kernelSize, strides: strides,
                 padding: padding.cName)
  }
}

public extension Tensor4D where Scalar : FloatingPoint {
  @_inlineable @inline(__always)
  // @differentiable(
  //   withRespectTo: (self, .0),
  //   gradient: _adjointConvolve2D(input:filter:primal:seed:)
  // )
  func convolved2D(
    withFilter filter: Tensor4D,
    strides: [Int32],
    padding: Padding
  ) -> Tensor4D {
    return #tfop("Conv2D", handle, filter, strides: strides,
                 padding: padding.cName)
  }

  // NOTE: Conv3D requires the existence of Tensor5D, since the input/filter
  // tensors for a Conv3D operation must have rank 5.
}
