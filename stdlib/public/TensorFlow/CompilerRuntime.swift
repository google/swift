//===-- CompilerRuntime.swift ---------------------------------*- swift -*-===//
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
// This file defines the Swift runtime support for TensorFlow computation.
//
//===----------------------------------------------------------------------===//

#if os(Linux) || os(FreeBSD)
  import Glibc
#else
  import Darwin
#endif
import CTensorFlow

/// The configuration for the compiler runtime.
/// TODO(hongm): Revisit the longer-term design.
public enum _TFCRuntimeConfig {
  /// When true, run the entire tensor computation in _TFCStartTensorProgram(),
  /// instead of running it in a thread.
  /// Set to true only for debugging purposes.
  static public var usesSynchronousExecution = false
}

//===----------------------------------------------------------------------===//
// - MARK: Tensor program
//===----------------------------------------------------------------------===//

/// Tensor program.
///
/// - Note: The call sequence for the APIs below must be one of the two:
///    init -> terminate()
///    init -> finish()
///   The finish/terminate APIs may only be called once.
public final class TensorProgram {
  let status: CTFStatus?
  let context: CTFContext?
  let op: CTFEOp?

  var returnValues: [CTensorHandle?]
  var returnValueCount: CInt

#if os(Linux) || os(FreeBSD)
  /// The thread to run tensor computation in.
  /// TODO(hongm): For pthread portability on Darwin and other OSes, see
  /// swift/stdlib/private/SwiftPrivatePthreadExtras/SwiftPrivatePthreadExtras.swift
  /// https://github.com/ketzusaka/Strand/blob/master/Sources/Strand.swift
  /// Also assess Windows portability (where pthread_create does not exist).
  var pthread: pthread_t
#endif

  /// Load the TF computation from a binary TF FunctionDef proto given by 'bytes'
  /// and 'size', start the computation, and return a state object as a unique
  /// identifier for that computation.
  ///
  /// - Parameters:
  ///   - programByteAddress: The address of the raw program.
  ///   - programByteCount: The number of bytes in the program.
  ///   - tensorArgumentAddress: The address to the buffer containing tensor
  ///     arguments as CTensorHandle.
  ///   - tensorArgumentCount: The number of tensor arguments to pass in.
  @_versioned
  init(programByteAddress: UnsafeRawPointer,
       programByteCount: Int,
       tensorArgumentAddress: UnsafePointer<CTensorHandle>,
       tensorArgumentCount: Int,
       // TODO(clattner): resultCount should go away when the runtime is
       // implemented with an async design.
       resultCount: Int) {
    let inputTensors = UnsafeBufferPointer(start: tensorArgumentAddress,
                                           count: tensorArgumentCount)

    // Create a status object that we reuse to check the results of the
    // TensorFlow runtime call we're making.  These should never fail unless
    // there is a compiler/runtime bug.
    self.status = TF_NewStatus()

    // TFE_Context is the host of the graph computation that we want to perform.
    let opts = TFE_NewContextOptions()
    self.context = TFE_NewContext(opts, status)
    TFE_DeleteContextOptions(opts)
    checkOk(status)

    // Here we have to do a fairly awkward dance to load the graph functions
    // and populate them into the TFE_Context.  We load the program as a
    // TF_Graph, then copy the functions out of it, then copy them into the
    // TFE_Context.
    let graph = TF_NewGraph()
    defer { TF_DeleteGraph(graph) }

    // TensorFlow loads things through TF_Buffer.  Create one that avoids
    // redundantly copying the program bytes.
    var programBuffer = TF_Buffer(data: programByteAddress,
                                  length: programByteCount,
                                  data_deallocator: { data, length in /*noop*/})

    let graphDefOptions = TF_NewImportGraphDefOptions()
    TF_GraphImportGraphDef(graph, &programBuffer, graphDefOptions, status)
    TF_DeleteImportGraphDefOptions(graphDefOptions)
    checkOk(status)

    // Now that we have all of the TF_Function objects in the graph, copy them
    // to standalone TF_Function's.
    let functionCount = TF_GraphNumFunctions(graph)
    let funcs =
      UnsafeMutablePointer<CTFFunction?>.allocate(capacity: Int(functionCount))
    TF_GraphGetFunctions(graph, funcs, functionCount, status)
    checkOk(status)

    // Finally, copy them again into the the TFE_Context so we can use them.
    for function in UnsafeBufferPointer(start: funcs,
                                        count: Int(functionCount)) {
      TFE_ContextAddFunction(context, function, status)
      checkOk(status)
      TF_DeleteFunction(function)
    }
    funcs.deallocate()

    // Now that we have them in our context, we can get ready to call the top
    // level function, which we know is always called "the_function".
    self.op = TFE_NewOp(context, "the_function", status)
    checkOk(status)

    for inputTensor in inputTensors {
      TFE_OpAddInput(op, inputTensor, status)
      checkOk(status)
    }

    self.returnValues = [CTensorHandle?](repeating: nil, count: resultCount)
    self.returnValueCount = CInt(resultCount)
#if os(Linux) || os(FreeBSD)
    self.pthread = 0
#endif
    if (!_TFCRuntimeConfig.usesSynchronousExecution) {
#if os(Linux)
      let programPtr = Unmanaged.passRetained(self).toOpaque()
      // When the closure gets long, split it into a static function that takes a
      // TensorProgram.
      let createStatus = pthread_create(&pthread, nil, { arg in
        let program = Unmanaged<TensorProgram>.fromOpaque(arg!).takeRetainedValue()
        TFE_Execute(program.op,
                    &program.returnValues,
                    &program.returnValueCount,
                    program.status)
        checkOk(program.status)
        return nil
      }, UnsafeMutableRawPointer(programPtr))
      // TODO(hongm): do error handling.
      internalConsistencyCheck(createStatus == 0)
#else
      print("asynchronous execution not supported on this host yet")
      abort()
#endif
    } else {
      // Log a debug message to differentiate from async computation.
      logToStderr("Running tensor computation synchronously.")
      let program = self
      TFE_Execute(program.op,
                  &program.returnValues,
                  &program.returnValueCount,
                  program.status)
      checkOk(program.status)
    }
  }

  deinit {
    TFE_DeleteOp(op)
    TFE_DeleteContext(context, status)
    checkOk(status)
    TF_DeleteStatus(status)
  }

  /// Terminate the computation as given by 'program', and clean up the state.
  @_versioned
  func terminate() {
    if (!_TFCRuntimeConfig.usesSynchronousExecution) {
#if os(Linux) || os(FreeBSD)
      // TODO(hongm): Assess TF's thread cancel support.
      let cancelStatus = pthread_cancel(pthread)
      internalConsistencyCheck(cancelStatus == 0)
#endif
    }
  }

  /// Wait for completion the computation as given by 'program', and returns
  /// output handles.
  @_versioned
  func finish() -> [CTensorHandle] {
    if (!_TFCRuntimeConfig.usesSynchronousExecution) {
#if os(Linux) || os(FreeBSD)
      let joinStatus = pthread_join(pthread, nil)
      internalConsistencyCheck(joinStatus == 0)
#endif
    }
    // Now that all the elements have been filled in, remove a level of optional.
    return self.returnValues.map { $0! }
  }
}

// ===-----------------------------------------------------------------------===
// - MARK: Compiler runtime entrypoints
// ===-----------------------------------------------------------------------===
// These are the entrypoints that are well-known to the compiler internals.  The
// signatures and forms must not be changed without updating the compiler.  Any
// code put into the body of these functions will end up being inlined into the
// user code, so they are generally just wrappers around the implementation
// above.

/// Load the TF computation from a binary TF FunctionDef proto given by 'bytes'
/// and 'size', start the computation, and return a state object as a unique
/// identifier for that computation.
///
/// - Parameters:
///   - programByteAddress: The address of the raw program.
///   - programByteCount: The number of bytes in the program.
///   - tensorArgumentAddress: The address to the buffer containing tensor
///     arguments as CTensorHandle.
///   - tensorArgumentCount: The number of tensor arguments to pass in.
@_inlineable
@_silgen_name("_swift_tfc_StartTensorProgram")
public func _TFCStartTensorProgram(
  _ programByteAddress: UnsafeRawPointer,
  _ programByteCount: Int,
  _ tensorArgumentAddress: UnsafePointer<CTensorHandle>,
  _ tensorArgumentCount: Int,
  // TODO(clattner): resultCount should go away when the runtime is implemented
  // with an async design.
  _ resultCount: Int
) -> TensorProgram {
  return TensorProgram(programByteAddress: programByteAddress,
                       programByteCount: programByteCount,
                       tensorArgumentAddress: tensorArgumentAddress,
                       tensorArgumentCount: tensorArgumentCount,
                       resultCount: resultCount)
}

/// Wait for completion the computation as given by 'program', and returns
/// results.
///
/// - Parameters:
///   - program: The tensor program to finish.
///   - tensorResultAddress: The address to an uninitialized buffer to accept
///     results of the computation.
///   - tensorResultCount: The number of results to accept from the computation.
/// - Note: The result address as passed in is pointing to uninitialized memory,
///   this must initialize the memory, transfering ownership of the tensor handles
///   to the caller.
@_inlineable
@_silgen_name("_swift_tfc_FinishTensorProgram")
public func _TFCFinishTensorProgram(
  _ program: TensorProgram,
  _ tensorResultAddress: UnsafeMutablePointer<CTensorHandle>,
  _ tensorResultCount: Int
) {
  let results = program.finish()
  internalConsistencyCheck(results.count == tensorResultCount,
    "internal compiler error: result count mismatch!")

  let resultBuffer = UnsafeMutableBufferPointer(start: tensorResultAddress,
    count: tensorResultCount)
  _ = resultBuffer.initialize(from: results)
}

/// Terminate the computation as given by 'program', and clean up the state.
///
/// - Parameters:
///   - program: The tensor program to terminate.
/// - Note: If the execution was synchronous, then this function does nothing.
@_inlineable
@_silgen_name("_swift_tfc_TerminateTensorProgram")
public func _TFCTerminateTensorProgram(_ program: TensorProgram) {
  program.terminate()
}

/// Wait for completion the computation as given by 'program', and returns
/// results.
///
/// - Parameters:
///   - program: The tensor program to finish.
///   - dtyle: TF data type of the tensor handle to create.
/// - Returns: A new CTensorHandle representing the scalar.
@_inlineable
@_silgen_name("_swift_tfc_CreateCTensorHandle")
public func _TFCCreateCTensorHandle<T>(_ value : T,
                                       _ dtype: TF_DataType) -> CTensorHandle {
  // Create a new CTensor and initialize it to the scalar value.
  let tensor = TF_AllocateTensor(dtype, nil, 0, MemoryLayout<T>.stride)
  TF_TensorData(tensor).assumingMemoryBound(to: T.self).initialize(to: value)
  // Create a new CTensorHandle from the CTensor.
  let status = TF_NewStatus()
  let cTensorHandle = TFE_NewTensorHandle(tensor, status)
  checkOk(status)
  TF_DeleteStatus(status)
  TF_DeleteTensor(tensor)
  return cTensorHandle!
}
