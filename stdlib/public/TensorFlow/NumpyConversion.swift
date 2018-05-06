//===-- NumPyConversion.swift ---------------------------------*- swift -*-===//
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
// This file defines conversion initializers from `numpy.ndarray` to
// `ShapedArray` and `Tensor`.
//
//===----------------------------------------------------------------------===//

#if canImport(Python)
import Python

extension ShapedArray : NumpyArrayConvertible
  where Scalar : NumpyScalarCompatible {
  public init?(numpyArray: PyValue) {
    guard let np = try? Python.attemptImport("numpy") else { return nil }

    // Check if input is a `numpy.ndarray` instance.
    guard Python.isinstance.call(with: numpyArray, np.ndarray) == true else {
      return nil
    }

    // Check if the dtype of the `ndarray` is compatible with the `Scalar`
    // type.
    guard Scalar.isCompatibleNumpyScalarType(numpyArray.dtype) else {
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

    // This code avoids calling `init<S : Sequence>(shape: [Int], scalars: S)`,
    // which inefficiently copies scalars one by one. Instead,
    // `init(shape: [Int], scalars: [Scalar])` is called, which efficiently
    // does a `memcpy` of the entire `scalars` array.
    // Unecessary copying is minimized.
    let dummyPointer = UnsafeMutablePointer<Scalar>.allocate(capacity: 1)
    let scalarCount = shape.reduce(1, *)
    var scalars: [Scalar] = Array(repeating: dummyPointer.move(),
                                  count: scalarCount)
    scalars.withUnsafeMutableBytes { mutPtr in
      mutPtr.baseAddress!.copyMemory(
        from: UnsafeRawPointer(ptr),
        byteCount: scalarCount * MemoryLayout<Scalar>.size)
    }
    self.init(shape: shape, scalars: scalars)
  }
}

extension Tensor : NumpyArrayConvertible where Scalar : NumpyScalarCompatible {
  public init?(numpyArray: PyValue) {
    guard let np = try? Python.attemptImport("numpy") else { return nil }

    // Check if input is a `numpy.ndarray` instance.
    guard Python.isinstance.call(with: numpyArray, np.ndarray) == true else {
      return nil
    }

    // Check if the dtype of the `ndarray` is compatible with the `Scalar`
    // type.
    guard Scalar.isCompatibleNumpyScalarType(numpyArray.dtype) else {
      return nil
    }

    let pyShape = numpyArray.__array_interface__["shape"]
    guard let dimensions = Array<Int32>(pyShape) else {
      return nil
    }
    let shape = TensorShape(dimensions)
    guard let ptrVal =
      UInt(numpyArray.__array_interface__["data"].tuple2.0) else {
      return nil
    }
    guard let ptr = UnsafePointer<Scalar>(bitPattern: ptrVal) else {
      return nil
    }
    let buffPtr = UnsafeBufferPointer(start: ptr,
                                      count: Int(shape.contiguousSize))
    self.init(shape: shape, scalars: buffPtr)
  }
}
#endif
