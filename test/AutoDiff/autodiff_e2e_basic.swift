// RUN: %target-swift-frontend -emit-sil %s | FileCheck %s

@differentiable(reverse, adjoint: adjointId)
func id(_ x: Float) -> Float {
  return x
}

func adjointId(_ x: Float, originalValue: Float, seed: Float) -> Float {
  return seed
}

_ = gradient(of: id)(2)

// CHECK: @{{.*}}id{{.*}}__grad_wrt_0
// CHECK-LABEL: @{{.*}}id{{.*}}__grad_wrt_0_s_p

#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
import Darwin
#else
import Glibc
#endif

@differentiable(reverse, primal: primalSigmoid, adjoint: adjointSigmoid)
func sigmoid(_ x: Double) -> Double {
  return 1.0 / (1.0 + exp(-x))
}

func primalSigmoid(_ x: Double) -> (checkpoints: (Double, Double, Double), result: Double) {
  let minusX = -x
  let expon = exp(minusX)
  let plus = 1.0 + expon
  let div = 1.0 / plus
  return (checkpoints: (minusX, expon, plus), result: div)
}

func adjointSigmoid(_ x: Double, checkpoints: (Double, Double, Double), result: Double, seed: Double) -> Double {
  return result * (1 - result)
}

_ = gradient(of: sigmoid)(3)

// CHECK: @{{.*}}sigmoid{{.*}}__grad_wrt_0
// CHECK: @{{.*}}sigmoid{{.*}}__grad_wrt_0_s_p
