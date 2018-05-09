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
// This file defines the Swift Run-time API for TensorFlow computation.
//
//===----------------------------------------------------------------------===//

import CTensorFlow

// The C type is TF_Status*
public typealias CTF_Status = OpaquePointer?

func checkOk(_ s: CTF_Status) {
  precondition(TF_GetCode(s) == TF_OK, String(cString: TF_Message(s)))
}

// The call sequence for the APIs below must be one of the two:
// init -> terminate()
// init -> finish()
public final class TensorProgram {
  // inputTensors is kept for debugging. Currently unused.
  let inputTensors: [AnyTensorHandle]
  let outputTensors: [AnyTensorHandle]

  // Load the TF computation from a binary TF FunctionDef proto given by 'bytes'
  // and 'size', start the computation, and return a state object as a unique
  // identifier for that computation.
  //
  // For now we only support programs that output 1 tensor. To support multiple
  // output tensors, we may need to extend this API to pass in a
  // outputTensorCount.
  @_versioned
  init(programByteAddress: UnsafeRawPointer,
       programByteCount: Int,
       tensorArgumentAddress: UnsafePointer<AnyTensorHandle>,
       tensorArgumentCount: Int) {
    inputTensors =
      Array(UnsafeBufferPointer(start: tensorArgumentAddress,
                                count: tensorArgumentCount))

    let s = TF_NewStatus()

    let tfFunc = TF_FunctionImportFunctionDef(programByteAddress,
                                              programByteCount, s)
    checkOk(s)

    // Now we start the graph computation.
    let opts = TFE_NewContextOptions()
    let ctx = TFE_NewContext(opts, s)
    checkOk(s)
    TFE_DeleteContextOptions(opts)

    TFE_ContextAddFunction(ctx, tfFunc, s)
    checkOk(s)
    TF_DeleteFunction(tfFunc)

    let op = TFE_NewOp(ctx, "the_function", s)
    checkOk(s)

    for inputTensor in inputTensors {
      let cTensorHandle = inputTensor.cTensorHandle
      TFE_OpAddInput(op, cTensorHandle, s)
      checkOk(s)
    }

    var retValCount: CInt = 1
    var retVals = [CTensorHandle](repeating: nil, count: Int(retValCount))
    TFE_Execute(op, &retVals, &retValCount, s)
    checkOk(s)
    precondition(retValCount == 1)
    TFE_DeleteOp(op)

    let outputTensors = retVals.map(AnyTensorHandle.init)

    TFE_DeleteContext(ctx, s)
    checkOk(s)
    TF_DeleteStatus(s)

    self.outputTensors = outputTensors
  }

  // Terminate the computation as given by 'program', and clean up the state.
  //
  // TODO(hongm): add real logic, including handling input/output and errors.
  @_versioned
  func terminate() {
  }

  // Wait for completion the computation as given by 'program', and returns output
  // handles.
  //
  // TODO(hongm): add real logic, including handling input/output and errors.
  @_versioned
  func finish() -> [AnyTensorHandle] {
    return outputTensors
  }
}



//===----------------------------------------------------------------------===//
//  Compiler runtime entrypoints
//===----------------------------------------------------------------------===//

// These are the entrypoints that are well-known to the compiler internals.  The
// signatures and forms must not be changed without updating the compiler.  Any
// code put into the body of these functions will end up being inlined into the
// user code, so they are generally just wrappers around the implementation
// above.

// Load the TF computation from a binary TF FunctionDef proto given by 'bytes'
// and 'size', start the computation, and return a state object as a unique
// identifier for that computation.
//
@_inlineable
@_silgen_name("_swift_tfc_StartTensorProgram")
public func _TFCStartTensorProgram(
  _ programByteAddress: UnsafeRawPointer,
  _ programByteCount: Int,
  _ tensorArgumentAddress: UnsafePointer<AnyTensorHandle>,
  _ tensorArgumentCount: Int
) -> TensorProgram {
  return TensorProgram(programByteAddress: programByteAddress,
                       programByteCount: programByteCount,
                       tensorArgumentAddress: tensorArgumentAddress,
                       tensorArgumentCount: tensorArgumentCount)
}

// Terminate the computation as given by 'program', and clean up the state.
//
@_inlineable
@_silgen_name("_swift_tfc_TerminateTensorProgram")
public func _TFCTerminateTensorProgram(_ program: TensorProgram) {
  program.terminate()
}

// Wait for completion the computation as given by 'program', and returns output
// handles.
//
@_inlineable
@_silgen_name("_swift_tfc_FinishTensorProgram")
public func _TFCFinishTensorProgram(
  _ program: TensorProgram
  ) -> [AnyTensorHandle] {
  return program.finish()
}


