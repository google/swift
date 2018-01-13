//===-- Tensor.swift ------------------------------------------*- swift -*-===//
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
// This is the core Tensor abstraction, which is conceptually equivalent to a
// NumPy ndarray.  It carries no rank information in its static type, so it can
// be used by model developers who don't want it.
//
//===----------------------------------------------------------------------===//

// NOTE: Pretty much everything here is marked @_inlineable/@_versioned.  This
// causes the body to be serialized into the generated Swift module, which
// allows it to be inlined into the user's code during deabstraction.  This is
// really gross, and will get better one way or the other, through compiler
// changes.

import CTensorFlow

//===----------------------------------------------------------------------===//
// Tensor type
//===----------------------------------------------------------------------===//

public struct Tensor<Element : TensorElementProtocol> {
  /// A tensor just contains a TensorHandle under the covers.  This is public to
  /// allow user defined ops, but shouldn't normally be used otherwise.
  public let handle: TensorHandle<Element>

  @_inlineable
  public init(_ handle: TensorHandle<Element>) {
    self.handle = handle
  }
}

//===----------------------------------------------------------------------===//
// Compiler intrinsics
//===----------------------------------------------------------------------===//
//
// By default, when a tensor value is implicitly passed between host and tensor
// code, the partitioning pass will generate a warning.  Users can indicate that
// they are doing something intentional by using these methods, which silences
// the warning.
//
// TODO: These would be nicer if defined as builtins rather than being "well
// known functions".

@_versioned @inline(never)
@_silgen_name("__tf_send")
func _TFSend<T>(_ handle: TensorHandle<T>) -> TensorHandle<T> {
  return handle
}

@_versioned @inline(never)
@_silgen_name("__tf_receive")
func _TFReceive<T>(_ handle: TensorHandle<T>) -> TensorHandle<T> {
  return handle
}

@_versioned @inline(never)
@_silgen_name("__tf_scalarize")
func _TFScalarize<T>(_ handle: TensorHandle<T>) -> T? {
  return handle.makeHostCopy().scalar
}

//===----------------------------------------------------------------------===//
// Memory transfer markers
//===----------------------------------------------------------------------===//

/// TODO: Remove when send/receive semantics gets revisited.
public extension Tensor {
  /// Indicate that this tensor is being moved to the accelerator.
  @_inlineable
  func toDevice() -> Tensor<Element> {
    return Tensor(_TFSend(handle))
  }

  /// Indicate that this tensor is being moved to the host.
  @_inlineable
  func toHost() -> Tensor<Element> {
    return Tensor(_TFReceive(handle))
  }
}

//===----------------------------------------------------------------------===//
// Initialization
//===----------------------------------------------------------------------===//

public extension Tensor {
  /// Perform an element conversion from Tensor<U> to Tensor<T>.
  @inline(never) // make @_inlineable when implemented.
  init?<FromType>(_ other: Tensor<FromType>) {
    fatalError("FIXME: Implement element conversion")
  }

  // Scalar (0-D) initializer, takes exactly one value.
  @_inlineable
  init(_ value: Element) {
    self.init(#tfop("Const", "dc:t", Element.self, value))
  }

  /// Vector (1-D) initializer, takes an array of values.
  @_inlineable
  init(_ vector: [Element]) {
    self.init(shape: [vector.count], elements: vector)
  }

  /// Matrix (2-D) initializer, takes an array of array of values.
  @_inlineable
  init(_ matrix: [[Element]]) {
    /// Sanity check
    guard let firstRow = matrix.first else {
      preconditionFailure("The first dimension is empty. Cannot infer shape.")
    }
    precondition(firstRow.count >= 1,
                 "The second dimension is empty. Dimension cannot be zero.")
    /// Now we make assumption about the shape.
    let rowCount = matrix.count, columnCount = firstRow.count
    let contiguousSize = rowCount * columnCount
    let byteSize = contiguousSize * MemoryLayout<Element>.stride
    /// Check rest dimensions.
    for row in matrix.dropFirst() {
      precondition(row.count == columnCount,
                   "Each dimension must have equal number of subdimensions.")
    }
    /// Initialize tensor and copy data.
    /// We don't want to delegate initialization to `init(shape:elements:)`
    /// because flattening `matrix` to an array is unnecessary cost.
    let cTensor = TF_AllocateTensor(Element.cDataType,
                                    [Int64(rowCount), Int64(columnCount)], 2,
                                    byteSize)
    let status = TF_NewStatus()
    let addr = TF_TensorData(cTensor).assumingMemoryBound(to: Element.self)
    /// Copy to TF_Tensor memory, one row at a time.
    for (i, row) in matrix.enumerated() {
      row.withUnsafeBufferPointer { ptr in
        addr.advanced(by: i * columnCount).assign(from: ptr.baseAddress!,
                                                  count: columnCount)
      }
    }
    /// Create handle and we are done.
    let cHandle = TFE_NewTensorHandle(cTensor, status)
    checkOk(status)
    TF_DeleteStatus(status)
    TF_DeleteTensor(cTensor)
    self.init(TensorHandle(cTensorHandle: cHandle!))
  }

  /// Arbitrary shape initializer.
  /// - Precondition: The number of elements should be the same as the
  /// product of all of shape's dimensions.
  @_inlineable
  init(shape: [Int], elements: [Element]) {
    let contiguousSize = shape.reduce(1, *)
    let byteSize = contiguousSize * MemoryLayout<Element>.stride
    precondition(elements.count == contiguousSize, """
      The number of elements don't match the shape
      """)
    let cTensor = TF_AllocateTensor(Element.cDataType,
                                    shape.map(Int64.init),
                                    Int32(shape.count),
                                    byteSize)
    let status = TF_NewStatus()
    /// Copy data
    let addr = TF_TensorData(cTensor).assumingMemoryBound(to: Element.self)
    elements.withUnsafeBufferPointer { ptr in
      addr.assign(from: ptr.baseAddress!, count: contiguousSize)
    }
    /// Create handle and we are done
    let cHandle = TFE_NewTensorHandle(cTensor, status)
    checkOk(status)
    TF_DeleteStatus(status)
    TF_DeleteTensor(cTensor)
    self.init(TensorHandle(cTensorHandle: cHandle!))
  }

  @_inlineable
  init(shape: [Int], repeating repeatedValue: Element) {
    let contiguousSize = shape.reduce(1, *)
    let byteSize = contiguousSize * MemoryLayout<Element>.stride
    let cTensor = TF_AllocateTensor(Element.cDataType,
                                    shape.map(Int64.init),
                                    Int32(shape.count),
                                    byteSize)
    let status = TF_NewStatus()
    /// Copy data
    let addr = TF_TensorData(cTensor).assumingMemoryBound(to: Element.self)
    /// Memset to `repeatedValue`
    addr.initialize(repeating: repeatedValue, count: contiguousSize)
    /// Create handle and we are done
    let cHandle = TFE_NewTensorHandle(cTensor, status)
    checkOk(status)
    TF_DeleteStatus(status)
    TF_DeleteTensor(cTensor)
    self.init(TensorHandle(cTensorHandle: cHandle!))
  }
}

//===----------------------------------------------------------------------===//
// Properties
//===----------------------------------------------------------------------===//

public extension Tensor {
  @_inlineable
  var shape: [Int] {
    return shapeTensor.elements.contiguousView.map(Int.init)
  }

  @_inlineable
  var rank: Int {
    // TODO: Optimize when we have rank-collapsing scalar getters
    return Int(rankTensor.elements.scalar!)
  }

  @_inlineable
  var totalElementCount: Int {
    // TODO: Optimize when we have rank-collapsing scalar getters
    return Int(totalElementCountTensor.elements.scalar!)
  }
}

//===----------------------------------------------------------------------===//
// Factory methods for numeric tensors
//===----------------------------------------------------------------------===//

public extension Tensor where Element : Numeric {
  /// Zero initializer, takes a list of dimensions.
  @_inlineable
  static func zeros(shape: [Int]) -> Tensor {
    return Tensor(shape: shape, repeating: 0)
  }

  /// Zero initializer, takes variadic dimensions.
  @_inlineable
  static func zeros(shape: Int...) -> Tensor {
    return zeros(shape: shape)
  }

  /// Ones initializer, takes a list of dimensions.
  @_inlineable
  static func ones(shape: [Int]) -> Tensor {
    return Tensor(shape: shape, repeating: 1)
  }

  /// Ones initializer, takes variadic dimensions.
  @_inlineable
  static func ones(shape: Int...) -> Tensor {
    return ones(shape: shape)
  }

  @inline(never) // make @_inlineable when implemented.
  static func eye(
    rowCount: Int, columnCount: Int? = nil, batchShape: [Int]? = nil
  ) -> Tensor {
    fatalError("FIXME: implement eye")
  }
}

//===----------------------------------------------------------------------===//
// Factory methods for floating point tensors
//===----------------------------------------------------------------------===//

public extension Tensor where Element : FloatingPoint {
  // def tf.random_normal(shape, mean=0.0, stddev=1.0, dtype=dtypes.float32,
  //                      seed=None, name=None):
  @inline(never) // make @_inlineable when implemented.
  static func randomNormal(
    shape: [Int], mean: Double = 0, stddev: Double = 1
  ) -> Tensor {
    fatalError("FIXME: implement randomNormal")
  }
}

//===----------------------------------------------------------------------===//
// Broadcasting and rank lifting
//===----------------------------------------------------------------------===//

public extension TensorElementProtocol {
  /// Broadcast the specified scalar value to be a tensor with the same rank as
  /// the specified other tensor, but with dimension=1 for each rank.
  @inline(never) // make @_inlineable when implemented.
  func broadcast(toRank rank: Int) -> Tensor<Self> {
    fatalError("FIXME: implement scalar broadcast")
  }
}

public extension Tensor {
  @inline(never) // make @_inlineable when implemented.
  func rankLifted(by dimensionCount: Int) -> Tensor {
    fatalError("FIXME: implement broadcast")
  }

  /// Broadcast the specified Tensor to a rank >= its current size, filling in
  /// the new dimensions with rank = 1.
  @inline(never)
  func broadcast(toRank rank: Int) -> Tensor {
    fatalError("FIXME: implement broadcast")
  }

  /// Broadcast self tensor to the same shape as the specified one.
  @inline(never) // make @_inlineable when implemented.
  func broadcast(to other: Tensor) -> Tensor {
    fatalError("FIXME: implement broadcast")
  }
}

//===----------------------------------------------------------------------===//
// Scalar conversion
//===----------------------------------------------------------------------===//

public extension Tensor {
  @_inlineable
  var isScalar: Bool {
    return rank == 0
  }

  /// Returns the underlying scalar from a 0-ranked Tensor.
  /// - precondition: Tensor is 0-ranked.
  @_inlineable
  var scalar: Element? {
    return Element(self)
  }
}

public extension TensorElementProtocol {
  @_inlineable
  init?(_ tensor: Tensor<Self>) {
    guard let scalar = _TFScalarize(tensor.handle) else {
      return nil
    }
    self = scalar
  }
}

//===----------------------------------------------------------------------===//
// Description and visualization
//===----------------------------------------------------------------------===//

/// Make "print(someTensor)" print a pretty form of the tensor.
extension Tensor : CustomStringConvertible {
  public var description: String {
    fatalError("Unimplemented")
  }
}

// Make Tensors show up nicely in the Xcode Playground results sidebar.
extension Tensor : CustomPlaygroundQuickLookable {
  public var customPlaygroundQuickLook: PlaygroundQuickLook {
    fatalError("Unimplemented")
  }
}

//===----------------------------------------------------------------------===//
// Array conversion
//===----------------------------------------------------------------------===//

public extension Tensor {
  @_inlineable
  var elements: ShapedArray<Element> {
    return handle.makeHostCopy()
  }
}
