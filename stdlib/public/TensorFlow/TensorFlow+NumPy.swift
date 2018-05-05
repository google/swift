//===-- TensorFlow+NumPy.swift --------------------------------*- swift -*-===//
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
// This file defines bridging from `numpy.ndarray` to `ShapedArray` and
// `Tensor`.
//
//===----------------------------------------------------------------------===//

import Python

public extension ShapedArray {
  init?(numpyArray: PyValue) {
    guard let np = try? Python.attemptImport("numpy") else {
      return nil
    }
    // Check if input is a `numpy.ndarray` instance.
    guard Python.isinstance.call(with: numpyArray, np.ndarray) == true else {
      return nil
    }

    // Check if the array's dtype matches the `Scalar` type.
    // (e.g. `np.float32` and `Float`).
    let scalarTypeMatch: Bool
    switch numpyArray.dtype {
    case np.bool_, Python.bool:
      scalarTypeMatch = Element.self == Bool.self
    case np.uint8:
      scalarTypeMatch = Element.self == UInt8.self
    case np.int8:
      scalarTypeMatch = Element.self == Int8.self
    case np.uint16:
      scalarTypeMatch = Element.self == UInt16.self
    case np.int16:
      scalarTypeMatch = Element.self == Int16.self
    case np.uint32:
      scalarTypeMatch = Element.self == UInt32.self
    case np.int32:
      scalarTypeMatch = Element.self == Int32.self
    case np.uint64:
      scalarTypeMatch = Element.self == UInt64.self
    case np.int64, Python.long:
      scalarTypeMatch = Element.self == Int64.self
    case np.float32:
      scalarTypeMatch = Element.self == Float.self
    case np.float64:
      scalarTypeMatch = Element.self == Double.self
    default:
      scalarTypeMatch = false
    }
    guard scalarTypeMatch else {
      return nil
    }

    let pyShape = numpyArray.__array_interface__["shape"]
    guard let shape = Array<Int>(pyShape) else {
      return nil
    }
    guard let ptrVal =
      UInt(numpyArray.__array_interface__["data"].tuple2.0) else {
      return nil
    }
    guard let ptr = UnsafePointer<Scalar>(bitPattern: ptrVal) else {
      return nil
    }
    let buffPtr = UnsafeBufferPointer(start: ptr, count: shape.reduce(1, *))
    self.init(shape: shape, scalars: buffPtr)
  }
}

public extension Tensor {
  init?(numpyArray: PyValue) {
    guard let array = ShapedArray<Scalar>(numpyArray: numpyArray) else {
      return nil
    }
    self.init(array)
  }
}
