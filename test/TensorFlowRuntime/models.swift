// RUN: %target-run-simple-swift
// REQUIRES: executable_test
//
// Simple model tests.
//
// NOTE: Only extremely simple models, such as MLP with 2000-iteration training
// loops, should be added here so that the testing time won't slow down
// too much.

import TensorFlow
import TestUtils
import StdlibUnittest

var ModelTests = TestSuite("Model")

ModelTests.testCPU("StraightLineXORTraining") {
  // FIXME: This test fails on Eager API.
  guard !_RuntimeConfig.usesTFEagerAPI else { return }
  // FIXME: This test fails on both CPU and GPU when --config=cuda is on.
#if CUDA
  return
#endif

  // Enable runtime support for loops.
  guard shouldDoLoopTest() else { return }

  // Hyper-parameters
  let iterationCount = 2000
  let learningRate: Float = 0.2
  var loss = Float.infinity

  // Parameters
  var w1 = Tensor<Float>(randomUniform: [2, 4])
  var w2 = Tensor<Float>(randomUniform: [4, 1])
  var b1 = Tensor<Float>(zeros: [1, 4])
  var b2 = Tensor<Float>(zeros: [1, 1])

  // Training data
  let x: Tensor<Float> = [[0, 0], [0, 1], [1, 0], [1, 1]]
  let y: Tensor<Float> = [[0], [1], [1], [0]]

  // Training loop
  // FIXME: Use a for-loop when it can be properly deabstracted.
  var i = 0
  repeat {
    // Forward pass
    let z1 = x.dot(w1) + b1
    let h1 = sigmoid(z1)
    let z2 = h1.dot(w2) + b2
    let pred = sigmoid(z2)

    // Backward pass
    let dz2 = pred - y
    let dw2 = h1.transposed(withPermutations: [1, 0]).dot(dz2)
    let db2 = dz2.sum(alongAxes: [0])
    let dz1 = dz2.dot(w2.transposed(withPermutations: [1, 0])) * h1 * (1 - h1)
    let dw1 = x.transposed(withPermutations: [1, 0]).dot(dz1)
    let db1 = dz1.sum(alongAxes: [0])

    // Gradient descent
    w1 -= dw1 * learningRate
    b1 -= db1 * learningRate
    w2 -= dw2 * learningRate
    b2 -= db2 * learningRate

    // Update current loss
    loss = dz2.squared().mean(alongAxes: [1, 0]).scalarized()

    // Update iteration count
    i += 1
  } while i < iterationCount

  // Check results
  expectLT(loss, 0.0001)
}

ModelTests.testCPU("XORClassifierTraining") {
  // FIXME: This test fails on Eager API.
  guard !_RuntimeConfig.usesTFEagerAPI else { return }
  // FIXME: This test fails on both CPU and GPU when --config=cuda is on.
#if CUDA
  return
#endif

  // Enable runtime support for loops.
  guard shouldDoLoopTest() else { return }

  // The classifier struct.
  struct MLPClassifier {
    // Parameters
    var w1 = Tensor<Float>(randomUniform: [2, 4])
    var w2 = Tensor<Float>(randomUniform: [4, 1])
    var b1 = Tensor<Float>(zeros: [1, 4])
    var b2 = Tensor<Float>(zeros: [1, 1])

    /// - TODO: Remove when deabstraction is implemented.
    @inline(__always)
    init() {}

    @_versioned @_inlineable @inline(__always)
    func prediction(for x: Tensor<Float>) -> Tensor<Float> {
      let o1 = sigmoid(x ⊗ w1 + b1)
      return sigmoid(o1 ⊗ w2 + b2)
    }

    @_versioned @_inlineable @inline(__always)
    func prediction(for x: Bool, _ y: Bool) -> Bool {
      let input = Tensor<Float>(Tensor([[x, y]]))
      let floatPred = prediction(for: input).scalarized()
      return abs(floatPred - 1) < 0.1
    }

    @_versioned @_inlineable @inline(__always)
    func loss(of prediction: Tensor<Float>,
              from exampleOutput: Tensor<Float>) -> Float {
      return (prediction - exampleOutput).squared()
        .mean(alongAxes: [0, 1]).scalarized()
    }

    @_versioned @_inlineable @inline(__always)
    mutating func train(inputBatch x: Tensor<Float>,
                        outputBatch y: Tensor<Float>,
                        iterationCount: Int, learningRate: Float) {
      // FIXME: Loop crasher b/73088003
      var i = 0
      repeat {
        let z1 = x.dot(w1) + b1
        let h1 = sigmoid(z1)
        let z2 = h1.dot(w2) + b2
        let pred = sigmoid(z2)

        let dz2 = pred - y
        let dw2 = h1.transposed(withPermutations: [1, 0]).dot(dz2)
        let db2 = dz2.sum(alongAxes: [0])
        let dz1 = dz2.dot(w2.transposed(withPermutations: [1, 0])) * h1 * (1 - h1)
        let dw1 = x.transposed(withPermutations: [1, 0]).dot(dz1)
        let db1 = dz1.sum(alongAxes: [0])

        // Gradient descent
        w1 -= dw1 * learningRate
        b1 -= db1 * learningRate
        w2 -= dw2 * learningRate
        b2 -= db2 * learningRate

        // Update iteration count
        i += 1
      } while i < iterationCount
    }
  }

  var classifier = MLPClassifier()
  classifier.train(
    inputBatch: [[0, 0], [0, 1], [1, 0], [1, 1]],
    outputBatch: [[0], [1], [1], [0]],
    iterationCount: 2000,
    learningRate: 0.2
  )
  // TODO: Add other expectations once code motion helps avoid send/receive.
  expectEqual(classifier.prediction(for: true, false), true)
}

runAllTests()
