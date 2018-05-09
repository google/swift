//===--- TFUtilities.h - TensorFlow lowering utilities ----------*- C++ -*-===//
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
// This defines the shared code that implements the various TensorFlow related
// lowerings and other transformations.
//
//===----------------------------------------------------------------------===//

#ifndef SWIFT_SILOPTIMIZER_TENSORFLOW_H
#define SWIFT_SILOPTIMIZER_TENSORFLOW_H

#include "swift/AST/TensorFlow.h"
#include "swift/SIL/SILFunction.h"

namespace swift {
namespace tf {
  /// This returns true if we should dump out intermediate results to standard
  /// out.  This is used for integration unit tests.
  bool shouldDumpIntermediates();

  /// If the specified type is the well-known TensorHandle<T> type, then return
  /// "T".  If not, return a null type.
  Type isTensorHandle(Type ty);
  bool isTensorHandle(SILType ty);

  /// This function maps a Swift type (either a language type like Float or an
  /// LLVM Builtin type like Builtin.f32) into the TensorFlow TF_DataType value.
  unsigned convertSwiftTypeToTF(Type ty);

  /// Represent information about a TensorFlow operation as represented in SIL
  /// as Builtin instructions.
  struct SILTensorOpInfo {
    /// The instruction being analyzed.
    BuiltinInst *inst;

    /// This is the name for the entire builtin that we'll partition out.
    StringRef builtinName;

    /// This is the TensorFlow name for the op.
    StringRef opName;

    /// One of these records exists for every operand that the BuiltinInst has,
    /// classifying the operand into a couple of buckets.  The most coarse grain
    /// classification is "input" vs "attribute": the inputs come first,
    /// followed by the attributes.  However, we need to be able to model the
    /// fact that some input arguments are aggregated together into a single
    /// input that is an array of tensors.  An integer attribute may be either
    /// a Tensor value or an integer-encoded DType, etc.
    enum class OperandClass {
      /// This marks three sorts of things:
      /// 1) A normal tensor input: the value is a TensorHandle.
      /// 2) A scalar input suitable for scalar promotion, used by the
      ///    tf.scalarToTensor pseudo-op, the value is a scalar value.
      /// 3) A tensor array (TensorFlow "InputList").  The value is a metatype
      ///    marker value (so we can represent empty arrays) followed by
      ///    InputElt elements that make up the array.
      Input,
      InputElt,     // Element of an input list.  Always a TensorHandle.

      Normal,       // No modifier.
      DType,        // This integer value is a dtype.
      Tensor,       // This array or scalar should be turned into a TF_Tensor.
      Shape,        // This array of integers is a shape specifier.

      Array,        // This marks a normal array value, the value is a metatype.
      ArrayElement, // This is a continuation element of an attribute array.
    };

    /// Return the string suffix for the specified attribute modifier.
    static const char *getOperandClassSuffix(OperandClass opClass);

    /// Return the operand class of the specified string form like "tensor"
    static llvm::Optional<OperandClass> getOperandClass(StringRef suffix);

    /// These are the names of any attribute operands at the end of the list.
    SmallVector<std::pair<StringRef, OperandClass>, 4> operandClasses;

    /// Return true if the specified operand is an input (not an attribute).
    bool isInput(unsigned operandNumber) const {
      return operandClasses[operandNumber].second == OperandClass::Input ||
             operandClasses[operandNumber].second == OperandClass::InputElt;
    }


    /// If the specified call is to a function that we can promote to an op,
    /// rewrite the instruction and return a new one that does so.  Otherwise,
    /// return the same instruction.
    static SILInstruction *decodeApply(ApplyInst *apply, StringRef name);

    /// Analyze the specified SIL instruction and return a SILTensorOpInfo
    /// result if the instruction is a valid tensor operation.  This is the
    /// way that SILTensorOpInfo's are created.
    static Optional<SILTensorOpInfo> decode(SILInstruction *inst);

    /// Verify that all operands to this op are correctly formed, e.g. that
    /// attribute operands are passed acceptable constants.  This returns a
    /// non-empty error string to emit if an error is detected.
    std::string checkAndDiagnoseOperands() const;

    /// Replace any indirect memory operands with direct references to the
    /// scalars they reference.  This potentially replaces the builtin
    /// instruction, so it returns the right one to use.
    // TODO(clattner): Remove this when deabstraction exists.
    SILInstruction *canonicalizeOperands();

    /// Return the SILValue for the specified scalar operand.
    SILValue getScalarOperand(unsigned operandNumber) const {
      return getScalarOperand(inst->getOperand(operandNumber));
    }
    static SILValue getScalarOperand(SILValue v);

    /// Return the constant instruction that defines the specified attribute
    /// operand, or null if the defining value isn't a valid constant for an
    /// attribute.
    SingleValueInstruction *getAttrOperand(unsigned operandNumber) const {
      return getAttrOperand(inst->getOperand(operandNumber));
    }
    static SingleValueInstruction *getAttrOperand(SILValue v);

  private:
    SILTensorOpInfo(BuiltinInst *inst) : inst(inst) {}
    bool decodeBuiltin();
    static SILInstruction *decodeTensorFromScalars(ApplyInst *inst);
    static SILInstruction *decodeTensorFromScalars1D(ApplyInst *inst);
    static SILInstruction *decodeTensorFromScalarsND(ApplyInst *inst);
  };


  /// The SIL location for operations we process are usually deep in the bowels
  /// of the tensor library code, which are all implementation details to the
  /// user.  As such, walk the inlining location of the specified node to return
  /// the first location *outside* of the tensor implementation goop.
  SILDebugLocation skipInternalLocations(SILDebugLocation loc);

  /// Skip over all the internal implementation details to get the source
  ///  location in user code.
  inline SILLocation getUserSourceLocation(SILDebugLocation loc) {
    return skipInternalLocations(loc).getLocation();
  }

  /// Get the user's source location for the specified value.  If it is an
  /// instruction, we can apply various heuristics to improve the precision of
  /// the returned location information.
  SILLocation getUserSourceLocation(SILValue value);
  SILLocation getUserSourceLocation(SILInstruction *inst);



  /// Lower the specified SIL function (which was formed by the partitioner)
  /// into a TensorFlow graph, and encode into a vector of bytes.
  ///
  std::vector<char> lowerTFGraph(SILFunction *fn);

  /// Return true if the specified type is a valid tensor element type.  For
  /// example, int128 and pointers are not.
  ///
  /// TODO: This should eventually consider information about the target
  /// deployment.
  inline bool isValidTensorFlowElementType(Type ty) {
    return convertSwiftTypeToTF(ty) != 0;
  }

} // end namespace tf
} // end namespace swift
#endif
