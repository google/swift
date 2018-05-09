// RUN: %target-swift-frontend -Xllvm -tf-dump-intermediates -O -emit-sil %s -verify | %FileCheck %s

import TensorFlow

public func testScalar(f: Float) {
  var x = Tensor<Float>(f) +    // expected-warning {{value implicitly copied to accelerator}}
          Tensor<Float>(1.0)
  x += x
  print(x)
}

// CHECK-LABEL: --- TFPartition Accelerator Result: {{.*}}testScalar{{.*}}
// CHECK: sil private @{{.*}}testScalar{{.*}} : $@callee_owned (TensorHandle<Float>) -> TensorHandle<Float> {
// CHECK: bb0(%0 : $TensorHandle<Float>):
// CHECK-NEXT:   %1 = metatype $@thick Float.Type
// CHECK-NEXT:   %2 = float_literal $Builtin.FPIEEE32, 0x3F800000 // 1
// CHECK-NEXT:   %3 = builtin "__tfop_Const__dc:t__"(%1 : $@thick Float.Type, %2 : $Builtin.FPIEEE32) : $TensorHandle<Float>
// CHECK-NEXT:   %4 = builtin "__tfop_Add__tt:t__"(%0 : $TensorHandle<Float>, %3 : $TensorHandle<Float>) : $TensorHandle<Float>
// CHECK-NEXT:   %5 = builtin "__tfop_Add__tt:t__"(%4 : $TensorHandle<Float>, %4 : $TensorHandle<Float>) : $TensorHandle<Float>
// CHECK-NEXT:   return %5 : $TensorHandle<Float>
// CHECK-NEXT: }


// CHECK-LABEL: --- TFPartition Host Result: {{.*}}testScalar{{.*}}
// CHECK: sil @{{.*}}testScalar{{.*}} : $@convention(thin) (Float) -> () {

// Graph lowering succeeds on this function
// CHECK: string_literal utf8 "{{.....}}
// CHECK-NEXT:  integer_literal $Builtin.Int64, {{[1-9]}}

// StartTensorProgram is called with one input tensor
// CHECK: [[TENSORS:%.*]] = struct $UnsafePointer<OpaquePointer> ({{%.*}} : $Builtin.RawPointer)
// CHECK-NEXT: [[TENSOR_COUNT:%.*]] = integer_literal $Builtin.Int64, 1
// CHECK-NEXT: [[TENSOR_COUNT_STRUCT:%.*]] = struct $Int ([[TENSOR_COUNT]] : $Builtin.Int64)
// CHECK: [[STARTFN:%.*]] = function_ref @_swift_tfc_StartTensorProgram
// CHECK-NEXT: [[PROGRAM:%.*]] = apply [[STARTFN]]({{%.*}}, {{%.*}}, [[TENSORS]], [[TENSOR_COUNT_STRUCT]]
// CHECK: [[FINISHFN:%.*]] = function_ref @_swift_tfc_FinishTensorProgram
// CHECK-NEXT: apply [[FINISHFN]]([[PROGRAM]],


public func testExitBranch(i : Int) {
  var x = Tensor<Float>(1.0)

  if i == 0 {
    return   // Should terminate the tensor program.
  }

  x += x
  print(x)
}

// The tensor program should have no branch.

// CHECK-LABEL: --- TFPartition Accelerator Result: {{.*}}testExitBranch{{.*}}
// CHECK: sil private @{{.*}}testExitBranch{{.*}} : $@callee_owned () -> TensorHandle<Float> {
// CHECK: bb0:
// CHECK-NEXT:   %0 = metatype $@thick Float.Type
// CHECK-NEXT:   %1 = float_literal $Builtin.FPIEEE32, 0x3F800000 // 1
// CHECK-NEXT:   %2 = builtin "__tfop_Const__dc:t__"(%0 : $@thick Float.Type, %1 : $Builtin.FPIEEE32) : $TensorHandle<Float>
// CHECK-NEXT:   %3 = builtin "__tfop_Add__tt:t__"(%2 : $TensorHandle<Float>, %2 : $TensorHandle<Float>) : $TensorHandle<Float>
// CHECK-NEXT:   return %3 : $TensorHandle<Float>
// CHECK-NEXT: }


// The host program should kill the tensor program if the early exit happens,
// and finish it on the normal path.

// CHECK-LABEL: --- TFPartition Host Result: {{.*}}testExitBranch{{.*}}
// CHECK: [[STARTFN:%.*]] = function_ref @_swift_tfc_StartTensorProgram
// CHECK-NEXT: [[PROGRAM:%.*]] = apply [[STARTFN]](
// CHECK: cond_br

// CHECK: bb1:
// CHECK: [[TERMFN:%.*]] = function_ref @_swift_tfc_TerminateTensorProgram
// CHECK-NEXT: apply [[TERMFN]]([[PROGRAM]]) : $@convention(thin) (@owned TensorProgram) -> ()
// CHECK: br bb3

// CHECK: bb2:
// CHECK: [[FINISHFN:%.*]] = function_ref @_swift_tfc_FinishTensorProgram
// CHECK-NEXT: apply [[FINISHFN]]([[PROGRAM]],

// CHECK: bb3:


