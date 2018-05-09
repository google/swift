// RUN: %target-swift-frontend -Xllvm -tf-dump-intermediates -O -emit-sil -verify %s
// RUN: %target-swift-frontend -Xllvm -tf-dump-intermediates -O -emit-sil -verify %s | %FileCheck %s
import TensorFlow

// This test is intended to verify that all of the operations end up in-graph:
// that there are no host/accelerator copies generated.  This specifically
// handles checking for top level code.



// This is testing that we can promote dataflow edges between ops that involve
// top level variables.  Because they are visible and accessible to nested code,
// they are represented as global variables, and require special promotion
// logic.

// This test also verifies that the assignment inside of
// 'localFunctionTouchingGlobalVar' is properly deabstracted.
//
let one = Tensor<Float>(1.0)
var x = one
func localFunctionTouchingGlobalVar() {
  x = one
}
x += one
x += one
#if false  // FIXME: Re-enable when deabstraction is smarter.
localFunctionTouchingGlobalVar()       // reassigns one to x
#else
x = one
#endif
x -= one

let y = Tensor<Float>(2.0)
let y2 = y*y*y*y

print(x)
print(y2)

// CHECK-LABEL: TFDeabstraction Result: main
// CHECK:  sil @main : $@convention(c) (Int32, UnsafeMutablePointer<Optional<UnsafeMutablePointer<Int8>>>) -> Int32 {
// CHECK:   [[ONE:%.*]] = builtin "__tfop_tfc.scalarToTensor
// CHECK:   [[ADD1:%.*]] = builtin "__tfop_Add,$in,$in"([[ONE]] : $TensorHandle<Float>, [[ONE]] : $TensorHandle<Float>)
// CHECK:   [[ADD2:%.*]] = builtin "__tfop_Add,$in,$in"([[ADD1]] : $TensorHandle<Float>, [[ONE]] : $TensorHandle<Float>)
// CHECK:   builtin "__tfop_Sub,$in,$in"([[ONE]] : $TensorHandle<Float>, [[ONE]] : $TensorHandle<Float>) : $TensorHandle<Float>
// CHECK:   [[TWO:%.*]] = builtin "__tfop_tfc.scalarToTensor
// CHECK:   strong_retain [[TWO]] : $TensorHandle<Float>
// CHECK:   strong_retain [[TWO]] : $TensorHandle<Float>
// CHECK:   [[MUL1:%.*]] = builtin "__tfop_Mul,$in,$in"([[TWO]] : $TensorHandle<Float>, [[TWO]] : $TensorHandle<Float>)
// CHECK:   strong_retain [[TWO]] : $TensorHandle<Float>
// CHECK:   [[MUL2:%.*]] = builtin "__tfop_Mul,$in,$in"([[MUL1]] : $TensorHandle<Float>, [[TWO]] : $TensorHandle<Float>)
// CHECK:   strong_retain [[TWO]] : $TensorHandle<Float>
// CHECK:   [[MUL3:%.*]] = builtin "__tfop_Mul,$in,$in"([[MUL2]] : $TensorHandle<Float>, [[TWO]] : $TensorHandle<Float>)
// CHECK-LABEL: } // end sil function 'main'

