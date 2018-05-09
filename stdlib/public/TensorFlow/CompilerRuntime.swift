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
// TODO:
// - Support async on platforms other than Linux and FreeBSD.
// - Revisit the concurrency model and see if Dispatch can be built without
//   Foundation.
// - Detach compiler runtime from the TensorFlow standard library to a separate
//   TensorFlowRuntime module.
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
public enum _RuntimeConfig {
  /// When true, run the entire tensor computation in _TFCStartTensorComputation(),
  /// instead of running it on a separate thread.
  /// - Note: Set to true only for debugging purposes.
  static public var usesSynchronousExecution = false

  /// When true, prints various debug messages on the runtime state.
  static public var printsDebugLog = false
}

/// The host of any tensor computation.
public final class _ExecutionContext {
  /// Global context storing all available devices, loaded functions, etc.
  public static let global: _ExecutionContext = _ExecutionContext()

  /// The TFE_Context object.
  private var cContext: CTFEContext

  /// The set of all loaded programs indexed by their unique address.
  private var loadedPrograms: Set<UnsafeRawPointer> = []

  /// The status for checking TensorFlow errors.
  private let status: CTFStatus = TF_NewStatus()

#if os(Linux) || os(FreeBSD)
  /// The mutex for preventing potential concurrent access.
  private var mutex: pthread_mutex_t = pthread_mutex_t()
#endif

  /// Initializes a new execution context by initializing available devices.
  private init() {
    let opts = TFE_NewContextOptions()
    cContext = TFE_NewContext(opts, status)
    TFE_DeleteContextOptions(opts)
    checkOk(status)
    // Initialize the mutex.
#if os(Linux) || os(FreeBSD)
    pthread_mutex_init(&mutex, nil)
#endif
  }

  deinit {
    TFE_DeleteContext(cContext, status)
    checkOk(status)
    TF_DeleteStatus(status)
#if os(Linux) || os(FreeBSD)
    pthread_mutex_destroy(&mutex)
#endif
  }
}

public extension _ExecutionContext {
  /// Remove all cached TensorFlow programs.
  /// - FIXME: This is temporarily added so that runtime tests can pass while
  ///   still using the old protobufs with "the_function" as the name of the
  ///   entry function.
  func reset() {
    sync { [unowned self] in
      // Delete the current context and create a new context.
      TFE_DeleteContext(self.cContext, self.status)
      checkOk(self.status)
      let opts = TFE_NewContextOptions()
      self.cContext = TFE_NewContext(opts, self.status)
      TFE_DeleteContextOptions(opts)
      checkOk(self.status)
    }
  }
}

internal extension _ExecutionContext {
  /// Synchronously execute the body, preventing asynchronous computation from
  /// corrupting the context data.
  private func sync<Result>(
    execute body: () throws -> Result
  ) rethrows -> Result {
#if os(Linux) || os(FreeBSD)
    let lockStatus = pthread_mutex_lock(&mutex)
    internalConsistencyCheck(lockStatus == 0)
    defer {
      let unlockStatus = pthread_mutex_unlock(&mutex)
      internalConsistencyCheck(unlockStatus == 0)
      // Create a cancellation point.
      pthread_testcancel()
    }
#endif // Async mode does not support other platforms, so it's already sync.
    return try body()
  }

  /// Invokes the given closure with the underlying C context. Access to the C
  /// context is guaranteed to be thread-safe within the closure.
  func withMutableCContext<Result>(
    execute body: (CTFEContext) throws -> Result
  ) rethrows -> Result {
    return try sync {
      try body(cContext)
    }
  }
}

fileprivate extension _ExecutionContext {
  /// Load a serialized TensorFlow program in binary proto format to the
  /// context. If the program has already been loaded, this function does
  /// nothing.
  /// - Parameters:
  ///   - address: The address of the serialized program in memory.
  ///   - count: The size of the program in bytes.
  func loadProgramInBytes(_ address: UnsafeRawPointer, count: Int) {
    sync { [unowned self] in
      // If the program is already loaded, do nothing.
      if self.loadedPrograms.contains(address) { return }

      // Here we have to do a fairly awkward dance to load the graph functions
      // and populate them into the TFE_Context.  We load the program as a
      // TF_Graph, then copy the functions out of it, then copy them into the
      // TFE_Context.
      let graph = TF_NewGraph()
      // TensorFlow loads things through TF_Buffer.  Create one that avoids
      // redundantly copying the program bytes.
      var programBuf = TF_Buffer(data: address, length: count,
                                 data_deallocator: nil)
      let graphDefOptions = TF_NewImportGraphDefOptions()
      TF_GraphImportGraphDef(graph, &programBuf, graphDefOptions, self.status)
      TF_DeleteImportGraphDefOptions(graphDefOptions)
      checkOk(self.status)
      // Now that we have all of the TF_Function objects in the graph, copy them
      // to standalone TF_Function's.
      let funcCount = TF_GraphNumFunctions(graph)
      // Allocate a buffer to accept functions.
      let funcs =
        UnsafeMutablePointer<CTFFunction?>.allocate(capacity: Int(funcCount))
      TF_GraphGetFunctions(graph, funcs, funcCount, self.status)
      checkOk(self.status)
      // Delete the graph as it's no longer needed.
      TF_DeleteGraph(graph)

      // Add functions to the context.
      for function in UnsafeBufferPointer(start: funcs, count: Int(funcCount)) {
        TFE_ContextAddFunction(self.cContext, function, self.status)
        checkOk(self.status)
        TF_DeleteFunction(function)
      }

      // Deallocate the function buffer as it's no longer used.
      funcs.deallocate()
      // Memorize the loaded program by address.
      loadedPrograms.insert(address)
    }
  }
}

//===----------------------------------------------------------------------===//
// - MARK: Tensor computation
//===----------------------------------------------------------------------===//

/// Tensor program.
///
/// - Note: The call sequence for the APIs below must be one of the two:
///    init -> terminate()
///    init -> finish()
///   The finish/terminate APIs may only be called once.
public final class _TensorComputation {
  /// The status for checking TensorFlow errors.
  let status: CTFStatus = TF_NewStatus()
  /// The TFE_Op that the program executes.
  let op: CTFEOp
  /// The values returned by the tensor program.
  var returnValues: [CTensorHandle?]
  /// The number of return values of the tensor program.
  var returnValueCount: CInt

#if os(Linux) || os(FreeBSD)
  /// The thread to run tensor computation in. The global config flag
  /// '_RuntimeConfig.usesSynchronousExecution' decides whether tensor
  /// computation should be synchronous: if true, this property will be nil.
  ///
  /// - TODO(hongm): For pthread portability on Darwin and other OSes, see
  ///   swift/stdlib/private/SwiftPrivatePthreadExtras/SwiftPrivatePthreadExtras.swift
  ///   https://github.com/ketzusaka/Strand/blob/master/Sources/Strand.swift
  ///   Also assess Windows portability (where pthread_create does not exist).
  private var pthread: pthread_t? =
    _RuntimeConfig.usesSynchronousExecution ? nil : pthread_t()
#endif

  /// Load the TF program from a binary TF FunctionDef proto given by
  /// 'programByteAddress' and 'programByteCount', and start the computation.
  ///
  /// - Parameters:
  ///   - programByteAddress: The address of the raw program.
  ///   - programByteCount: The number of bytes in the program.
  ///   - tensorArgumentAddress: The address to the buffer containing tensor
  ///     arguments as CTensorHandle.
  ///   - tensorArgumentCount: The number of tensor arguments to pass in.
  ///
  /// - TODO(clattner): resultCount should go away when the runtime is
  ///   implemented with an async design.
  @_versioned
  init(programByteAddress: UnsafeRawPointer,
       programByteCount: Int,
       entryFunctionNameAddress: UnsafePointer<Int8>,
       tensorArgumentAddress: UnsafePointer<CTensorHandle>,
       tensorArgumentCount: Int,
       resultCount: Int) {
    let inputTensors = UnsafeBufferPointer(start: tensorArgumentAddress,
                                           count: tensorArgumentCount)

    // Get global execution context, which caches all our tensor programs.
    let context = _ExecutionContext.global

    // Make sure the program is loaded to the context.
    context.loadProgramInBytes(programByteAddress, count: programByteCount)

    // Now that we have them in our context, we can get ready to get the top
    // level function and create an op.
    self.op = context.withMutableCContext { [status] ctx in
      defer { checkOk(status) }
      return TFE_NewOp(ctx, entryFunctionNameAddress, status)
    }

    // Populate the op's input list.
    for inputTensor in inputTensors {
      TFE_OpAddInput(op, inputTensor, status)
      checkOk(status)
    }

    self.returnValues = [CTensorHandle?](repeating: nil, count: resultCount)
    self.returnValueCount = CInt(resultCount)

    debugLog("Starting TF graph execution.")

    // If it's asynchronous, we start a pthread that calls execute().
    // NOTE: Currently, asynchronous execution is only supported on Linux.
    if pthread != nil {
#if os(Linux) || os(FreeBSD)
      // The function to launch in the parallel thread.
      func threadBody(
        _ arg: UnsafeMutableRawPointer?
      ) -> UnsafeMutableRawPointer? {
        // Set the cancelability of the detached thread.
        pthread_setcanceltype(Int32(PTHREAD_CANCEL_DEFERRED), nil)
        // Execute the tensor computation.
        let computation: _TensorComputation =
          Unmanaged.fromOpaque(arg!).takeRetainedValue()
        computation.execute()
        checkOk(computation.status)
        return nil
      }
      let creationStatus = pthread_create(
        &self.pthread!, nil, threadBody,
        Unmanaged.passRetained(self).toOpaque()
      )
      // TODO(hongm): do error handling.
      internalConsistencyCheck(creationStatus == 0)
#else
      fatalError("Asynchronous execution not supported on this host yet")
#endif
    }
    // If it's asynchronous, we call execute() on the main thread directly.
    else {
      // Log a debug message to differentiate from async computation.
      debugLog("Running tensor computation synchronously.")
      execute()
    }
    debugLog("Exiting _TensorComputation.init().")
  }

  deinit {
    TFE_DeleteOp(op)
    TF_DeleteStatus(status)
  }
}

private extension _TensorComputation {
  /// Execute the computation using TensorFlow Eager.
  /// NOTE: This is to be called by the initializer. The computation gets
  /// executed on initialization, thus this method will not be exposed to users.
  private func execute() {
    TFE_Execute(op, &returnValues, &returnValueCount, status)
    checkOk(status)
  }
}

public extension _TensorComputation {
  /// Terminate the computation, and clean up the state.
  func terminate() {
#if os(Linux) || os(FreeBSD)
    if let pthread = pthread {
      // TODO(hongm): Assess TF's thread cancel support.
      let cancelStatus = pthread_cancel(pthread)
      internalConsistencyCheck(cancelStatus == 0)
      self.pthread = nil
    }
#endif
  }

  /// Wait for completion the computation as given by 'program', and returns
  /// output handles.
  func finish() -> [CTensorHandle] {
    debugLog("Calling _TensorComputation.finish().")
#if os(Linux) || os(FreeBSD)
    if let pthread = pthread {
      let joinStatus = pthread_join(pthread, nil)
      internalConsistencyCheck(joinStatus == 0)
      self.pthread = nil
    }
#endif
    debugLog("Done executing TF graph.")

    // Now that all the elements have been filled in, remove a level of
    // optional.
    return returnValues.map { $0! }
  }
}

//===----------------------------------------------------------------------===//
// - MARK: Compiler runtime entrypoints
//===----------------------------------------------------------------------===//
// These are the entrypoints that are well-known to the compiler internals.  The
// signatures and forms must not be changed without updating the compiler.  Any
// code put into the body of these functions will end up being inlined into the
// user code, so they are generally just wrappers around the implementation
// above.

/// Load the TF computation from a binary TF FunctionDef proto given by 'bytes'
/// and 'size', start the computation, and return a _TensorComputation object as
/// a unique identifier for that computation.
///
/// - Parameters:
///   - programByteAddress: The address of the raw program.
///   - programByteCount: The number of bytes in the program.
///   - tensorArgumentAddress: The address to the buffer containing tensor
///     arguments as CTensorHandle.
///   - tensorArgumentCount: The number of tensor arguments to pass in.
@_inlineable
@_silgen_name("_swift_tfc_StartTensorComputation")
public func _TFCStartTensorComputation(
  _ programByteAddress: UnsafeRawPointer,
  _ programByteCount: Int,
  _ entryFunctionNameAddress: UnsafePointer<Int8>,
  _ tensorArgumentAddress: UnsafePointer<CTensorHandle>,
  _ tensorArgumentCount: Int,
  // TODO(clattner): resultCount should go away when the runtime is implemented
  // with an async design.
  _ resultCount: Int
) -> _TensorComputation {
  return _TensorComputation(programByteAddress: programByteAddress,
                            programByteCount: programByteCount,
                            entryFunctionNameAddress: entryFunctionNameAddress,
                            tensorArgumentAddress: tensorArgumentAddress,
                            tensorArgumentCount: tensorArgumentCount,
                            resultCount: resultCount)
}

/// Wait for completion the computation as given by 'program', and returns
/// results.
///
/// - Parameters:
///   - computation: The tensor computation to finish.
///   - tensorResultAddress: The address to an uninitialized buffer to accept
///     results of the computation.
///   - tensorResultCount: The number of results to accept from the computation.
/// - Note: The result address as passed in is pointing to uninitialized memory,
///   this must initialize the memory, transfering ownership of the tensor handles
///   to the caller.
@_inlineable
@_silgen_name("_swift_tfc_FinishTensorComputation")
public func _TFCFinishTensorComputation(
  _ computation: _TensorComputation,
  _ tensorResultAddress: UnsafeMutablePointer<CTensorHandle>,
  _ tensorResultCount: Int
) {
  let results = computation.finish()
  internalConsistencyCheck(results.count == tensorResultCount,
    "internal compiler error: result count mismatch!")
  tensorResultAddress.initialize(from: results, count: tensorResultCount)
}

/// Terminate the computation as given by 'program', and clean up the state.
///
/// - Parameters:
///   - program: The tensor program to terminate.
/// - Note: If the execution was synchronous, then this function does nothing.
@_inlineable
@_silgen_name("_swift_tfc_TerminateTensorComputation")
public func _TFCTerminateTensorComputation(_ computation: _TensorComputation) {
  computation.terminate()
}

/// Create a scalar CTensorHandle value for the given data type.
/// - Parameters:
///   - value: The scalar value.
///   - dtype: The TF data type of the tensor handle to create.
/// - Returns: A new CTensorHandle representing the scalar.
/// - Precondition: T must conform to AccelerableTensorUnit and 'dtype' must be
///   equal to T's corresponding data type.
/// - TODO(rxwei): Constrain T to AccelerableTensorUnit and remove the
///   precondition. This requires the compiler to emit a call to the generic
///   function.
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
