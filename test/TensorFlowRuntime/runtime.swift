// RUN: %target-run-simple-swift
// REQUIRES: executable_test

import StdlibUnittest
import CTensorFlow
import TensorFlow

var RuntimeTests = TestSuite("Runtime")

// The C Type of s is TF_Status*.
func checkOk(_ s: OpaquePointer?) {
  precondition(TF_OK == TF_GetCode(s), String(cString: TF_Message(s)))
}

func createFloatTensorHandle(_ f: Float) -> CTensorHandle {
  let s = TF_NewStatus()
  let in_t = TF_AllocateTensor(TF_FLOAT, nil, 0, 4)

  // This chunk of code does: *reinterpret_cast<float*>(TF_TensorData(in_t)) = f
  let inputRawPtr: UnsafeMutableRawPointer = TF_TensorData(in_t)!
  let inputPtr = inputRawPtr.bindMemory(to: CFloat.self, capacity: 1)
  inputPtr.pointee = CFloat(f)

  let cTensorHandle = TFE_NewTensorHandle(in_t, s)!
  checkOk(s)
  TF_DeleteTensor(in_t)
  TF_DeleteStatus(s)
  return cTensorHandle
}

func checkFloatValueNear(_ outputTensor: CTensorHandle, _ expectedVal: Float) {
  let s = TF_NewStatus()
  let out_t = TFE_TensorHandleResolve(outputTensor, s)
  checkOk(s)
  TF_DeleteStatus(s)

  precondition(TF_TensorByteSize(out_t) == 4)
  // This does: actualValue = *(float*)TF_TensorData(out_t)
  let actualValue: CFloat = TF_TensorData(out_t)!.bindMemory(to: CFloat.self, capacity: 1).pointee
  print("The actual output float value is \(actualValue)")
  precondition(expectedVal - actualValue < 0.0001, String(actualValue))
  TF_DeleteTensor(out_t)
}

func decodeHex(_ string: String) -> [UInt8] {
  func hexToInt(_ c : UInt8) -> UInt8 {
    switch c {
    case UInt8(ascii: "0")...UInt8(ascii: "9"): return c - UInt8(ascii: "0")
    case UInt8(ascii: "a")...UInt8(ascii: "f"): return c - UInt8(ascii: "a") + 10
    case UInt8(ascii: "A")...UInt8(ascii: "F"): return c - UInt8(ascii: "A") + 10
    default: fatalError("invalid hexadecimal character")
    }
  }

  var result: [UInt8] = []
  assert(string.count & 1 == 0, "must get a pair of hexadecimal characters")
  var it = string.utf8.makeIterator()
  while let byte1 = it.next(),
        let byte2 = it.next() {  // we know we have an even byte length.
    result.append((hexToInt(byte1) << 4) | hexToInt(byte2))
  }

  return result
}

func runProgram(_ progName: String,
  _ graphProtoInHex: String,
  _ inputTensors: [CTensorHandle],
  shouldAbort: Bool = false
) -> [CTensorHandle] {
  let graphProto = decodeHex(graphProtoInHex)
  print("The input graph of program \(progName) has \(graphProto.count) bytes.")
  let program = _TFCStartTensorProgram(graphProto,
                                       graphProto.count,
                                       inputTensors,
                                       inputTensors.count,
                                       /*number of output tensors*/1)
  let outputBuffer = UnsafeMutablePointer<CTensorHandle>.allocate(capacity: 1)

  defer {
    outputBuffer.deallocate()
  }

  if (shouldAbort) {
    _TFCTerminateTensorProgram(program)
    return []
  }

  _TFCFinishTensorProgram(program, outputBuffer, 1)
  // Load the result tensor, taking ownership from the unsafe pointer.
  let resultTensor = outputBuffer.move()

  print("Program \(progName) produced a tensor.")

  return [resultTensor]
}

// 0 input and output tensors.
func runConst() {
  /* The corresponding Swift program:
     public func testTestorExample() {
       let x = Tensor<Float>(2.0)
     }
   */
  let graphProto = decodeHex("12680A660A0E0A0C7468655F66756E6374696F6E1A540A236F702E5F54303174313774657374546573746F724578616D706C657979462E332E31331205436F6E73742A190A0576616C75651210420E08011204120208012A04000000402A0B0A0564747970651202300122020818")

  let program = _TFCStartTensorProgram(graphProto,
                                       graphProto.count,
                                       /*inputTensors=*/[],
                                       /*inputTensors.count=*/0,
                                       /*number of output tensors*/0)

  // Even though there is no output tensor, we create outputBuffer via
  // UnsafeMutablePointer.allocate(). The generated SIL code differs from what
  // TF compiler would generate.
  let outputBuffer = UnsafeMutablePointer<CTensorHandle>.allocate(capacity: 0)
  _TFCFinishTensorProgram(program, outputBuffer, 0)
  outputBuffer.deallocate()
}

func runTanh() {
  /* The corresponding Swift program:
       public func g(value: Float) {
        let b = Tensor<Float>([value])
        let a = tanh(b)
        print(a)
      }
   */
  let graphProto = "12E8010AE5010A3A0A0C7468655F66756E6374696F6E12090A056172675F3018011A1F0A1B6F705F5F7430317431673576616C75657973665F74665F335F313318011A320A076172675F305F30120B506C616365686F6C6465722A0D0A05736861706512043A0218012A0B0A056474797065120230011A330A1B6F702E5F5430317431673576616C75657953665F74462E332E3133120454616E681A056172675F302A070A015412023001223E0A1B6F705F5F7430317431673576616C75657973665F74665F335F3133121F6F702E5F5430317431673576616C75657953665F74462E332E31333A793A3022020818"

  let outputTensors = runProgram("Tanh", graphProto, [createFloatTensorHandle(1.2)])

  checkFloatValueNear(outputTensors[0], 0.833655)
}

func runAdd(shouldAbort: Bool) {
  /* The corresponding Swift program:
  public func f() {
    let b = Tensor1D<Float>(1,2,3)
    let c = Tensor1D<Float>(1,2,4)
    let a = b+c
  }
  */
  let graphProto = "1289020A86020A3C0A0C7468655F66756E6374696F6E12090A056172675F30180112090A056172675F3118011A160A126F705F5F7430317431667979665F335F313318011A320A076172675F305F30120B506C616365686F6C6465722A0B0A056474797065120230012A0D0A05736861706512043A0218011A320A076172675F315F30120B506C616365686F6C6465722A0B0A056474797065120230012A0D0A05736861706512043A0218011A300A126F702E5F5430317431667979462E332E313312034164641A056172675F301A056172675F312A070A015412023001222C0A126F705F5F7430317431667979665F335F313312166F702E5F5430317431667979462E332E31333A7A3A3022020818"

  let outputTensors = runProgram("Add", graphProto,
                                 [createFloatTensorHandle(1.2),
                                  createFloatTensorHandle(3.4)],
                                 shouldAbort: shouldAbort)

  if (!shouldAbort) {
      checkFloatValueNear(outputTensors[0], 1.2+3.4)
  }
}

RuntimeTests.test("Runtime/DecodeHexTest") {
  assert(decodeHex("01FF") == [1, 255])
  assert(decodeHex("8001") == [128, 1])
  assert(decodeHex("80a1bcd3") == [128, 161, 188, 211])
}

RuntimeTests.test("Runtime/BasicConstTest") {
  runConst()
}

RuntimeTests.test("Runtime/BasicTanhTest") {
  runTanh()
}

RuntimeTests.test("Runtime/BasicAddTest") {
  runAdd(shouldAbort: false)
}

RuntimeTests.test("Runtime/AddThenAbbortTest") {
  runAdd(shouldAbort: true)
}

RuntimeTests.test("Runtime/BasicTanhSyncTest") {
  _TFCRuntimeConfig.usesSynchronousExecution = true
  runTanh()
}

// Tests are currently executed sequentially, so if there are any subsequent
// tests intended for async runtime, set _TFCRuntimeConfig.usesSynchronousExecution = false
// for those tests.

runAllTests()
