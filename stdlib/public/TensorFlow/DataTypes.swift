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

  /// This converts a scalar to a 0d TensorHandle that contains the value.
  /// Users should call the _TFMakeScalarTensor wrapper function.
  static func _makeScalarTensor(_ scalar: Self) -> TensorHandle<Self>
}

// This is the implementation of the _getScalarOrDie requirement for each
// concrete type below.  We use this round-about approach to implement the
// global _TFGetScalarOrDie function in order to ensure that the noinline
// SIL functions below have non-generic type signatures.  This is important for
// the inner workings of the partitioning pass.
private func _TFGetScalarOrDieImpl<Scalar>(_ handle: TensorHandle<Scalar>) -> Scalar {
  return handle.makeHostCopy().scalar!
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

  @_inlineable @inline(__always)
  public static func _makeScalarTensor(_ scalar: Bool) -> TensorHandle<Bool> {
    return #tfop("tfc.scalarToTensor", scalar)
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
  @_inlineable @inline(__always)
  public static func _makeScalarTensor(_ scalar: Int8) -> TensorHandle<Int8> {
    return #tfop("tfc.scalarToTensor", scalar)
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
  @_inlineable @inline(__always)
  public static func _makeScalarTensor(_ scalar: UInt8) -> TensorHandle<UInt8> {
    return #tfop("tfc.scalarToTensor", scalar)
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
  @_inlineable @inline(__always)
  public static func _makeScalarTensor(_ scalar: Int16) -> TensorHandle<Int16> {
    return #tfop("tfc.scalarToTensor", scalar)
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
  @_inlineable @inline(__always)
  public static func _makeScalarTensor(_ scalar: UInt16)
  -> TensorHandle<UInt16> {
    return #tfop("tfc.scalarToTensor", scalar)
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
  @_inlineable @inline(__always)
  public static func _makeScalarTensor(_ scalar: Int32) -> TensorHandle<Int32> {
    return #tfop("tfc.scalarToTensor", scalar)
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
  @_inlineable @inline(__always)
  public static func _makeScalarTensor(_ scalar: UInt32)
  -> TensorHandle<UInt32> {
    return #tfop("tfc.scalarToTensor", scalar)
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
  @_inlineable @inline(__always)
  public static func _makeScalarTensor(_ scalar: Int64) -> TensorHandle<Int64> {
    return #tfop("tfc.scalarToTensor", scalar)
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
  @_inlineable @inline(__always)
  public static func _makeScalarTensor(_ scalar: UInt64)
  -> TensorHandle<UInt64> {
    return #tfop("tfc.scalarToTensor", scalar)
  }
}

extension Int : AccelerableByTensorFlow {
  public static var _tensorFlowDataType: _TensorDataType {
    return _TensorDataType(TF_INT64)
  }
  @_silgen_name("__tf_get_scalar_or_die_Int") @inline(never)
  public static func _getScalarOrDie(_ handle: TensorHandle<Int>) -> Int {
    return _TFGetScalarOrDieImpl(handle)
  }
  @_inlineable @inline(__always)
  public static func _makeScalarTensor(_ scalar: Int) -> TensorHandle<Int> {
    return #tfop("tfc.scalarToTensor", scalar)
  }
}

extension UInt : AccelerableByTensorFlow {
  public static var _tensorFlowDataType: _TensorDataType {
    return _TensorDataType(TF_UINT64)
  }
  @_silgen_name("__tf_get_scalar_or_die_UInt") @inline(never)
  public static func _getScalarOrDie(_ handle: TensorHandle<UInt>) -> UInt {
    return _TFGetScalarOrDieImpl(handle)
  }
  @_inlineable @inline(__always)
  public static func _makeScalarTensor(_ scalar: UInt) -> TensorHandle<UInt> {
    return #tfop("tfc.scalarToTensor", scalar)
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
  @_inlineable @inline(__always)
  public static func _makeScalarTensor(_ scalar: Float) -> TensorHandle<Float> {
    return #tfop("tfc.scalarToTensor", scalar)
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
  @_inlineable @inline(__always)
  public static func _makeScalarTensor(_ scalar: Double)
  -> TensorHandle<Double> {
    return #tfop("tfc.scalarToTensor", scalar)
  }
}
