// RUN: %target-sil-opt -assume-parsing-unqualified-ownership-sil %s | %FileCheck %s

sil_stage raw

import Builtin
import Swift

sil public @bar_adj : $@convention(thin) (Float, Float, Float, Float) -> (Float, Float) {
entry(%0: $Float, %1: $Float, %2: $Float, %3: $Float):
  %ret = tuple (%0: $Float, %1: $Float)
  return %ret: $(Float, Float)
}

// CHECK-LABEL: sil [differentiable wrt 0, 1 adjoint @bar_adj] @bar
sil public [differentiable wrt 0, 1 adjoint @bar_adj] @bar : $@convention(thin) (Float, Float) -> Float {
entry(%0: $Float, %1: $Float):
  return %0: $Float
}