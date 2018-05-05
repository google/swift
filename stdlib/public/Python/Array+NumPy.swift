//===-- Array+NumPy.swift -------------------------------------*- swift -*-===//
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
// This file defines bridging from `numpy.ndarray` to `Array`.
//
//===----------------------------------------------------------------------===//

public extension Array {
  init?(numpyArray: PyValue) {
    guard let np = try? Python.attemptImport("numpy") else {
      return nil
    }
    // Check if input is a `numpy.ndarray` instance.
    guard Python.isinstance.call(with: numpyArray, np.ndarray) == true else {
      return nil
    }

    // Check if the array's dtype matches the `Element` type.
    // (e.g. `np.float32` and `Float`).
    var elementTypeMatch = false
    switch numpyArray.dtype {
    case np.float32, np.single:
      elementTypeMatch = Element.self == Float.self
    case np.double, np.float, np.float64:
      elementTypeMatch = Element.self == Double.self
    // ... handle more cases
    default: break
    }
    guard elementTypeMatch else {
      return nil
    }

    // Only 1-D `ndarray` instances can be converted to `Array`.
    let pyShape = numpyArray.__array_interface__["shape"]
    guard let shape = [Int](pyShape) else {
      return nil
    }
    guard shape.count == 1 else {
      return nil
    }

    guard let ptrVal =
      UInt(numpyArray.__array_interface__["data"].tuple2.0) else {
      return nil
    }
    guard let ptr = UnsafePointer<Element>(bitPattern: ptrVal) else {
      return nil
    }
    let buffPtr = UnsafeBufferPointer(start: ptr, count: shape[0])
    self.init(buffPtr)
  }
}
