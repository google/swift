//===-- DataTypes.swift ---------------------------------------*- swift -*-===//
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
// This file defines the AccelerableByTensorFlow and related helpers.
//
// TODO:
// - Many ops that support int32 and int64 don't support int8 and int16.
//   Consider removing Int8's and Int16's conformance to
//   AccelerableByTensorFlow.
//
//===----------------------------------------------------------------------===//

import CTensorFlow

public struct _TensorDataType {
  internal var cDataType: TF_DataType

  fileprivate init(_ cDataType: TF_DataType) {
    self.cDataType = cDataType
  }
}

public protocol AccelerableByTensorFlow {
  /// The underlying TensorFlow data type.
  /// - Note: This is not intended for general use.
  static var _tensorFlowDataType: _TensorDataType { get }

  // Hooks used by the TFPartition pass for primitive operations on tensors.
  // These should not be called directly or implemented.

  /// This converts a TensorHandle that is known to have a 0d value into
  /// the scalar that it produces.  Users should call the _TFGetScalarOrDie
  /// wrapper function.
  static func _getScalarOrDie(_ handle: TensorHandle<Self>) -> Self

  /// This converts a TensorHandle into a scalar if it is 0d, or returns nil
  /// otherwise.  Users should call the _TFGetScalar wrapper function.
  static func _getScalar(_ handle: TensorHandle<Self>) -> Self?

  /// This converts a scalar to a 0d TensorHandle that contains the value.
  /// Users should call the _TFMakeScalarTensor wrapper function.
  static func _makeScalarTensor(_ scalar: Self) -> TensorHandle<Self>

  /// This indicates that it is safe to hoist the specified computation that
  /// creates a tensor to being a parameter that is passed in from outside of
  /// the tensor program.
  static func _makeHoistable(_ fn: () -> TensorHandle<Self>)
    -> TensorHandle<Self>
}

// This is the implementation of the _getScalarOrDie requirement for each
// concrete type below.  We use this round-about approach to implement the
// global _TFGetScalarOrDie function in order to ensure that the noinline
// SIL functions below have non-generic type signatures.  This is important for
// the inner workings of the partitioning pass.
private
func _TFGetScalarOrDieImpl<Scalar>(_ handle: TensorHandle<Scalar>) -> Scalar {
  return handle.makeHostCopy().scalar!
}

// This is the implementation of the _getScalar requirement for each concrete
// type below.  We use this round-about approach to implement the
// global _TFGetScalar function in order to ensure that the noinline
// SIL functions below have non-generic type signatures.  This is important for
// the inner workings of the partitioning pass.
private
func _TFGetScalarImpl<Scalar>(_ handle: TensorHandle<Scalar>) -> Scalar? {
  return handle.makeHostCopy().scalar
}

internal extension AccelerableByTensorFlow {
  @_versioned
  static var cDataType: TF_DataType {
    return _tensorFlowDataType.cDataType
  }
}

extension Bool : AccelerableByTensorFlow {
  public static var _tensorFlowDataType: _TensorDataType {
    return _TensorDataType(TF_BOOL)
  }
  @_silgen_name("__tf_get_scalar_or_die_Bool") @inline(never)
  public static func _getScalarOrDie(_ handle: TensorHandle<Bool>) -> Bool {
    return _TFGetScalarOrDieImpl(handle)
  }
  @_silgen_name("__tf_get_scalar_Bool") @inline(never)
  public static func _getScalar(_ handle: TensorHandle<Bool>) -> Bool? {
    return _TFGetScalarImpl(handle)
  }
  @_inlineable @inline(__always)
  public static func _makeScalarTensor(_ scalar: Bool) -> TensorHandle<Bool> {
    return #tfop("tfc.scalarToTensor", scalar)
  }
  @_silgen_name("__tf_hoistable_Bool") @_optimize(none) @inline(never)
  public static func _makeHoistable(_ fn: () -> TensorHandle<Bool>)
    -> TensorHandle<Bool> {
    return fn()
  }
}

extension Int8 : AccelerableByTensorFlow {
  public static var _tensorFlowDataType: _TensorDataType {
    return _TensorDataType(TF_INT8)
  }
  @_silgen_name("__tf_get_scalar_or_die_Int8") @inline(never)
  public static func _getScalarOrDie(_ handle: TensorHandle<Int8>) -> Int8 {
    return _TFGetScalarOrDieImpl(handle)
  }
  @_silgen_name("__tf_get_scalar_Int8") @inline(never)
  public static func _getScalar(_ handle: TensorHandle<Int8>) -> Int8? {
    return _TFGetScalarImpl(handle)
  }
  @_inlineable @inline(__always)
  public static func _makeScalarTensor(_ scalar: Int8) -> TensorHandle<Int8> {
    return #tfop("tfc.scalarToTensor", scalar)
  }
  @_silgen_name("__tf_hoistable_Int8") @_optimize(none) @inline(never)
  public static func _makeHoistable(_ fn: () -> TensorHandle<Int8>)
    -> TensorHandle<Int8> {
    return fn()
  }
}

extension UInt8 : AccelerableByTensorFlow {
  public static var _tensorFlowDataType: _TensorDataType {
    return _TensorDataType(TF_UINT8)
  }
  @_silgen_name("__tf_get_scalar_or_die_UInt8") @inline(never)
  public static func _getScalarOrDie(_ handle: TensorHandle<UInt8>) -> UInt8 {
    return _TFGetScalarOrDieImpl(handle)
  }
  @_silgen_name("__tf_get_scalar_UInt8") @inline(never)
  public static func _getScalar(_ handle: TensorHandle<UInt8>) -> UInt8? {
    return _TFGetScalarImpl(handle)
  }
  @_inlineable @inline(__always)
  public static func _makeScalarTensor(_ scalar: UInt8) -> TensorHandle<UInt8> {
    return #tfop("tfc.scalarToTensor", scalar)
  }
  @_silgen_name("__tf_hoistable_UInt8") @_optimize(none) @inline(never)
  public static func _makeHoistable(_ fn: () -> TensorHandle<UInt8>)
    -> TensorHandle<UInt8> {
    return fn()
  }
}

extension Int16 : AccelerableByTensorFlow {
  public static var _tensorFlowDataType: _TensorDataType {
    return _TensorDataType(TF_INT16)
  }
  @_silgen_name("__tf_get_scalar_or_die_Int16") @inline(never)
  public static func _getScalarOrDie(_ handle: TensorHandle<Int16>) -> Int16 {
    return _TFGetScalarOrDieImpl(handle)
  }
  @_silgen_name("__tf_get_scalar_Int16") @inline(never)
  public static func _getScalar(_ handle: TensorHandle<Int16>) -> Int16? {
    return _TFGetScalarImpl(handle)
  }
  @_inlineable @inline(__always)
  public static func _makeScalarTensor(_ scalar: Int16) -> TensorHandle<Int16> {
    return #tfop("tfc.scalarToTensor", scalar)
  }
  @_silgen_name("__tf_hoistable_Int16") @_optimize(none) @inline(never)
  public static func _makeHoistable(_ fn: () -> TensorHandle<Int16>)
    -> TensorHandle<Int16> {
    return fn()
  }
}

extension UInt16 : AccelerableByTensorFlow {
  public static var _tensorFlowDataType: _TensorDataType {
    return _TensorDataType(TF_UINT16)
  }
  @_silgen_name("__tf_get_scalar_or_die_UInt16") @inline(never)
  public static func _getScalarOrDie(_ handle: TensorHandle<UInt16>) -> UInt16 {
    return _TFGetScalarOrDieImpl(handle)
  }
  @_silgen_name("__tf_get_scalar_UInt16") @inline(never)
  public static func _getScalar(_ handle: TensorHandle<UInt16>) -> UInt16? {
    return _TFGetScalarImpl(handle)
  }
  @_inlineable @inline(__always)
  public static func _makeScalarTensor(_ scalar: UInt16)
  -> TensorHandle<UInt16> {
    return #tfop("tfc.scalarToTensor", scalar)
  }
  @_silgen_name("__tf_hoistable_UInt16") @_optimize(none) @inline(never)
  public static func _makeHoistable(_ fn: () -> TensorHandle<UInt16>)
    -> TensorHandle<UInt16> {
    return fn()
  }
}

extension Int32 : AccelerableByTensorFlow {
  public static var _tensorFlowDataType: _TensorDataType {
    return _TensorDataType(TF_INT32)
  }
  @_silgen_name("__tf_get_scalar_or_die_Int32") @inline(never)
  public static func _getScalarOrDie(_ handle: TensorHandle<Int32>) -> Int32 {
    return _TFGetScalarOrDieImpl(handle)
  }
  @_silgen_name("__tf_get_scalar_Int32") @inline(never)
  public static func _getScalar(_ handle: TensorHandle<Int32>) -> Int32? {
    return _TFGetScalarImpl(handle)
  }
  @_inlineable @inline(__always)
  public static func _makeScalarTensor(_ scalar: Int32) -> TensorHandle<Int32> {
    return #tfop("tfc.scalarToTensor", scalar)
  }
  @_silgen_name("__tf_hoistable_Int32") @_optimize(none) @inline(never)
  public static func _makeHoistable(_ fn: () -> TensorHandle<Int32>)
    -> TensorHandle<Int32> {
    return fn()
  }
}

extension UInt32 : AccelerableByTensorFlow {
  public static var _tensorFlowDataType: _TensorDataType {
    return _TensorDataType(TF_UINT32)
  }
  @_silgen_name("__tf_get_scalar_or_die_UInt32") @inline(never)
  public static func _getScalarOrDie(_ handle: TensorHandle<UInt32>) -> UInt32 {
    return _TFGetScalarOrDieImpl(handle)
  }
  @_silgen_name("__tf_get_scalar_UInt32") @inline(never)
  public static func _getScalar(_ handle: TensorHandle<UInt32>) -> UInt32? {
    return _TFGetScalarImpl(handle)
  }
  @_inlineable @inline(__always)
  public static func _makeScalarTensor(_ scalar: UInt32)
  -> TensorHandle<UInt32> {
    return #tfop("tfc.scalarToTensor", scalar)
  }
  @_silgen_name("__tf_hoistable_UInt32") @_optimize(none) @inline(never)
  public static func _makeHoistable(_ fn: () -> TensorHandle<UInt32>)
    -> TensorHandle<UInt32> {
    return fn()
  }
}

extension Int64 : AccelerableByTensorFlow {
  public static var _tensorFlowDataType: _TensorDataType {
    return _TensorDataType(TF_INT64)
  }
  @_silgen_name("__tf_get_scalar_or_die_Int64") @inline(never)
  public static func _getScalarOrDie(_ handle: TensorHandle<Int64>) -> Int64 {
    return _TFGetScalarOrDieImpl(handle)
  }
  @_silgen_name("__tf_get_scalar_Int64") @inline(never)
  public static func _getScalar(_ handle: TensorHandle<Int64>) -> Int64? {
    return _TFGetScalarImpl(handle)
  }
  @_inlineable @inline(__always)
  public static func _makeScalarTensor(_ scalar: Int64) -> TensorHandle<Int64> {
    return #tfop("tfc.scalarToTensor", scalar)
  }
  @_silgen_name("__tf_hoistable_Int64") @_optimize(none) @inline(never)
  public static func _makeHoistable(_ fn: () -> TensorHandle<Int64>)
    -> TensorHandle<Int64> {
    return fn()
  }
}

extension UInt64 : AccelerableByTensorFlow {
  public static var _tensorFlowDataType: _TensorDataType {
    return _TensorDataType(TF_UINT64)
  }
  @_silgen_name("__tf_get_scalar_or_die_UInt64") @inline(never)
  public static func _getScalarOrDie(_ handle: TensorHandle<UInt64>) -> UInt64 {
    return _TFGetScalarOrDieImpl(handle)
  }
  @_silgen_name("__tf_get_scalar_UInt64") @inline(never)
  public static func _getScalar(_ handle: TensorHandle<UInt64>) -> UInt64? {
    return _TFGetScalarImpl(handle)
  }
  @_inlineable @inline(__always)
  public static func _makeScalarTensor(_ scalar: UInt64)
  -> TensorHandle<UInt64> {
    return #tfop("tfc.scalarToTensor", scalar)
  }
  @_silgen_name("__tf_hoistable_UInt64") @_optimize(none) @inline(never)
  public static func _makeHoistable(_ fn: () -> TensorHandle<UInt64>)
    -> TensorHandle<UInt64> {
    return fn()
  }
}

extension Float : AccelerableByTensorFlow {
  public static var _tensorFlowDataType: _TensorDataType {
    return _TensorDataType(TF_FLOAT)
  }
  @_silgen_name("__tf_get_scalar_or_die_Float") @inline(never)
  public static func _getScalarOrDie(_ handle: TensorHandle<Float>) -> Float {
    return _TFGetScalarOrDieImpl(handle)
  }
  @_silgen_name("__tf_get_scalar_Float") @inline(never)
  public static func _getScalar(_ handle: TensorHandle<Float>) -> Float? {
    return _TFGetScalarImpl(handle)
  }
  @_inlineable @inline(__always)
  public static func _makeScalarTensor(_ scalar: Float) -> TensorHandle<Float> {
    return #tfop("tfc.scalarToTensor", scalar)
  }
  @_silgen_name("__tf_hoistable_Float") @_optimize(none) @inline(never)
  public static func _makeHoistable(_ fn: () -> TensorHandle<Float>)
    -> TensorHandle<Float> {
    return fn()
  }
}

extension Double : AccelerableByTensorFlow {
  public static var _tensorFlowDataType: _TensorDataType {
    return _TensorDataType(TF_DOUBLE)
  }
  @_silgen_name("__tf_get_scalar_or_die_Double") @inline(never)
  public static func _getScalarOrDie(_ handle: TensorHandle<Double>) -> Double {
    return _TFGetScalarOrDieImpl(handle)
  }
  @_silgen_name("__tf_get_scalar_Double") @inline(never)
  public static func _getScalar(_ handle: TensorHandle<Double>) -> Double? {
    return _TFGetScalarImpl(handle)
  }
  @_inlineable @inline(__always)
  public static func _makeScalarTensor(_ scalar: Double)
  -> TensorHandle<Double> {
    return #tfop("tfc.scalarToTensor", scalar)
  }
  @_silgen_name("__tf_hoistable_Double") @_optimize(none) @inline(never)
  public static func _makeHoistable(_ fn: () -> TensorHandle<Double>)
    -> TensorHandle<Double> {
    return fn()
  }
}
