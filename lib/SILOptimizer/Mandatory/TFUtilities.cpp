//===--- TFUtilities.cpp - TensorFlow lowering utilities ------------------===//
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

#include "TFUtilities.h"
#include "swift/AST/ASTContext.h"
#include "swift/AST/DiagnosticsSIL.h"
#include "swift/SIL/SILBuilder.h"
#include "swift/SIL/SILModule.h"
#include "llvm/ADT/StringExtras.h"
#include "llvm/ADT/StringSwitch.h"
#include "llvm/Support/CommandLine.h"
#ifdef SWIFT_ENABLE_TENSORFLOW
#ifdef CMAKE_INTDIR
#include "tensorflow/c/c_api.h"
#else
#include "tensorflow/c/c_api.h"
#endif
#endif

using namespace swift;
using namespace tf;
typedef SILTensorOpInfo::OperandClass OperandClass;

template<typename...T, typename...U>
static InFlightDiagnostic
diagnose(ASTContext &Context, SourceLoc loc, Diag<T...> diag, U &&...args) {
  return Context.Diags.diagnose(loc, diag, std::forward<U>(args)...);
}

static llvm::cl::opt<bool>
TFDumpIntermediates("tf-dump-intermediates", llvm::cl::init(false),
              llvm::cl::desc("Dump intermediate results in TensorFlow passes"));

/// This returns true if we should dump out intermediate results to standard
/// out.  This is used for integration unit tests.
bool tf::shouldDumpIntermediates() {
  return TFDumpIntermediates;
}


/// If the specified type is the well-known TensorHandle<T> type, then return
/// "T".  If not, return a null type.
Type tf::isTensorHandle(Type ty) {
  if (auto bgct = ty->getAs<BoundGenericClassType>()) {
    if (bgct->getDecl()->getNameStr() == "TensorHandle") {
      assert(bgct->getGenericArgs().size() == 1 && "Expected one generic arg");
      return bgct->getGenericArgs()[0];
    }
  }
  return Type();
}

bool tf::isTensorHandle(SILType ty) {
  return (bool)isTensorHandle(ty.getSwiftRValueType());
}

static bool is64(Type ty) {
  return ty->getASTContext().LangOpts.Target.isArch64Bit();
}

/// This function maps a Swift type (either a language type like Float or an
/// LLVM Builtin type like Builtin.f32) into the TensorFlow TF_DataType value.
///
/// This returns 0 (which is an invalid tensorflow type ID) on error.
///
unsigned tf::convertSwiftTypeToTF(Type ty) {
#ifdef SWIFT_ENABLE_TENSORFLOW
  // Handle wrappers like Float, which come up in TensorHandle<Float>
  if (auto *s = ty->getAs<StructType>()) {
    // Make sure the type is defined inside the Swift module.
    auto context = s->getDecl()->getDeclContext()->getParentModule();
    if (!context || context->getName().str() != "Swift")
      return 0;

    return llvm::StringSwitch<unsigned>(s->getDecl()->getNameStr())
      .Case("Bool", TF_BOOL)
      .Case("Int8", TF_INT8)
      .Case("UInt8", TF_UINT8)
      .Case("Int16", TF_INT16)
      .Case("UInt16", TF_UINT16)
      .Case("Int32", TF_INT32)
      .Case("UInt32", TF_UINT32)
      .Case("Int64", TF_INT64)
      .Case("UInt64", TF_UINT64)
      .Case("Int8", TF_INT8)
      .Case("UInt8", TF_UINT8)
      .Case("Float", TF_FLOAT)
      .Case("Double", TF_DOUBLE)
      .Case("Int", is64(s) ? TF_INT64 : TF_INT32)
      .Case("UInt", is64(s) ? TF_UINT64 : TF_UINT32)
      .Default(0);
  }

  // BuiltinIntegerType doesn't carry sign information, which TensorFlow needs,
  // so we can't rely on getting type information from the builtin types
  // themselves.  For now we'll just use signed types.
  if (auto *BII = ty->getAs<BuiltinIntegerType>()) {
    if (BII->getWidth().isPointerWidth())
      return is64(ty) ? TF_INT64 : TF_INT32;

    switch (BII->getFixedWidth()) {
    case 1: return TF_BOOL;
    case 8: return TF_INT8;
    case 16: return TF_INT16;
    case 32: return TF_INT32;
    case 64: return TF_INT64;
    }
  }

  if (auto *BIF = ty->getAs<BuiltinFloatType>()) {
    switch (BIF->getFPKind()) {
    case BuiltinFloatType::IEEE16: return TF_HALF;
    case BuiltinFloatType::IEEE32: return TF_FLOAT;
    case BuiltinFloatType::IEEE64: return TF_DOUBLE;
    case BuiltinFloatType::IEEE80:
    case BuiltinFloatType::IEEE128:
    case BuiltinFloatType::PPC128:
      return 0;
    }
  }
#endif
  return 0;
}

/// If the specified type is a Swift.Array or some element type, then return the
/// element type.  Otherwise, return a null Type.
static Type getArrayElementType(Type ty) {
  if (auto bgst = ty->getAs<BoundGenericStructType>())
    if (bgst->getDecl() == bgst->getASTContext().getArrayDecl())
      return bgst->getGenericArgs()[0];
  return Type();
}

/// Given a SILValue that may be an array, attempt to decode it into the
/// literal constant values that make up its elements.  If this fails or if
/// the value is not an array, this returns false.  Otherwise it decodes the
/// array and returns the element initializer in elements.
static bool decodeArrayElements(SILValue value,
                                SmallVectorImpl<SILValue> &elements,
                                Type &elementType) {
  elementType = getArrayElementType(value->getType().getSwiftRValueType());
  if (!elementType) return false;

  // Handle the standard patterns for array initialization.  'Value' is an
  // alloc_ref that is wrapped up in abstractions like this:
  //
  // %39 = alloc_ref [tail_elems $Int * %0 : $Builtin.Word] $_Contiguo....<Int>
  // %43 = unchecked_ref_cast %39 : $_ContiguousArrayStorage<Int> to ...
  // %44 = struct $_BridgeStorage<...> (%43 : $Builtin.BridgeObject)
  // %45 = struct $_ArrayBuffer<Int> (%44 : $_BridgeStorage<...>)
  // %46 = struct $Array<Int> (%45 : $_ArrayBuffer<Int>)
  //
  // Targets without ObjC bridging are slightly different, we handle both forms
  // here.
  AllocRefInst *allocRef = nullptr;
  while (!(allocRef = dyn_cast<AllocRefInst>(value))) {
    if (auto *si = dyn_cast<StructInst>(value)) {
      if (si->getNumOperands() != 1) return false;
      value = si->getOperand(0);
    } else if (auto *urci = dyn_cast<UncheckedRefCastInst>(value)) {
      value = urci->getOperand();
    } else if (auto *uci = dyn_cast<UpcastInst>(value)) {
      value = uci->getOperand();
    } else if (auto *globalValue = dyn_cast<GlobalValueInst>(value)) {
      // If we found a GlobalValueInst, then we're referring to an array that
      // got moved to being a static initializer.
      auto *init = dyn_cast_or_null<ObjectInst>(
              globalValue->getReferencedGlobal()->getStaticInitializerValue());
      if (!init) return false;

      // The initializer elements are the tail elements of the object_inst, see
      // if they are all decodable.
      for (auto elt : init->getTailElements())
        elements.push_back(elt);

      return true;
    } else if (auto *rptr = dyn_cast<RawPointerToRefInst>(value)) {
      // The empty array is specially recognized by the optimizer and
      // transformed into a well-known global produced by the standard library.
      // Uses of it look like this:
      //   %5 = global_addr @_swiftEmptyArrayStorage : $*_SwiftEmptyArrayStorage
      //   %6 = address_to_pointer %5 : $*_SwiftEmptyArrayStorage to $RawPointer
      //   %7 = raw_pointer_to_ref %6 : $RawPointer to $_EmptyArrayStorage
      //   %8 = unchecked_ref_cast %7 : $_EmptyArrayStorage to $BridgeObject
      auto a2p = dyn_cast<AddressToPointerInst>(rptr->getOperand());
      if (!a2p) return false;
      auto *ga = dyn_cast<GlobalAddrInst>(a2p->getOperand());

      elements.clear();
      return ga &&
             ga->getReferencedGlobal()->getName() == "_swiftEmptyArrayStorage";
    } else {
      return false;
    }
  }

  // The allocation must be of a constant number of elements.
  if (allocRef->getNumOperands() != 1 ||
      !isa<IntegerLiteralInst>(allocRef->getOperand(0)))
    return false;

  uint64_t numElements = cast<IntegerLiteralInst>(allocRef->getOperand(0))
                                            ->getValue().getLimitedValue();

  // Given the allocation, we then look for stores.  First there is going to be
  // an upcast to _ContiguousArrayStorageBase which is an internal
  // implementation detail that has the tail elements on it.  Then there will
  // be a ref_tail_addr, then indexed stores will hang off of it, like this:
  //
  // %40 = upcast %39 : $_ContiguousArrayStorage<Int> to $_ContiguousArra...
  // %47 = ref_tail_addr %40 : $_ContiguousArrayStorageBase, $Int
  // store %13 to %47 : $*Int
  // %49 = index_addr %47 : $*Int, %14 : $Builtin.Word
  // store %13 to %49 : $*Int
  auto *uci = allocRef->getSingleUserOfType<UpcastInst>();
  if (!uci) return false;
  auto *rti = uci->getSingleUserOfType<RefTailAddrInst>();
  if (!rti) return false;

  elements.resize(numElements);

  for (auto *use : rti->getUses()) {
    auto *user = use->getUser();

    uint64_t index = 0;
    if (auto *iai = dyn_cast<IndexAddrInst>(user)) {
      auto *ili = dyn_cast<IntegerLiteralInst>(iai->getOperand(1));
      if (!ili)
        return false;
      index = ili->getValue().getLimitedValue();
      if (auto *iaiUse = iai->getSingleUse())
        user = iaiUse->getUser();
      else
        return false;
    }

    // Check to see if we have a store to a valid index that hasn't been stored
    // to yet.
    auto *si = dyn_cast<StoreInst>(user);
    if (!si || index >= elements.size() || elements[index] != SILValue())
      return false;

    // If we got a store to a valid index, it must be our element.
    elements[index] = si->getOperand(0);

    // Track how many elements we see so we can know if we got them all.
    --numElements;
  }

  // Make sure that all of the elements were found.
  if (numElements != 0)
    return false;

  return true;
}

SILValue SILTensorOpInfo::getScalarOperand(SILValue v) {
  // We have to handle two kinds of operands: SIL address operands and normal
  // values.
  if (!v->getType().isAddress()) {
    // If we have a normal operand, handle the form where a StructInst is
    // Swift stdlib type (e.g. Int/Float) wrapping an underlying LLVM value.
    if (auto *SI = dyn_cast<StructInst>(v))
      if (SI->getNumOperands() == 1)
        return SI->getOperand(0);

    return v;
  }

  // Because we're often coming from generic code, we frequently get a value
  // passed by-address.  Check for an alloc_stack with a single store to it and
  // consume the stored value.
  if (auto *ASI = dyn_cast<AllocStackInst>(v)) {
    if (auto *store = ASI->getSingleUserOfType<StoreInst>())
      return getScalarOperand(store->getSrc());
  }

  // Otherwise this is a by-address value that we can't handle:
  // FIXME: The proper way to deal with this is with a deabstraction pass,
  // which will guarantee generic specialization promotes the builtin operand
  // to never be an address.
  return SILValue();
}

/// If the specified value is a valid value for an attribute, return the
/// instruction that provides the value, otherwise null.
SingleValueInstruction *SILTensorOpInfo::getAttrOperand(SILValue v) {
  // If the value is a string value, then we need to peel off all the SIL
  // instructions between the String struct value and the underlying
  // string_literal instruction.
  auto &ctx = v->getType().getSwiftRValueType()->getASTContext();
  if (v->getType().getSwiftRValueType()->isEqual(
                                     ctx.getStringDecl()->getDeclaredType())) {
    auto str = v;
    // Strip off the specific set of instructions we expect to form the string
    // literal.
    while (1) {
      if (auto sli = dyn_cast<StringLiteralInst>(str))
        return sli->getEncoding() == StringLiteralInst::Encoding::UTF8
                ? sli : nullptr;

      if (auto si = dyn_cast<StructInst>(str)) {
        assert(si->getNumOperands() >= 1 &&
               "Expect String, UnsafeMutableRawPointer, and _StringCore types");
        str = si->getOperand(0);
        continue;
      }

      if (auto ei = dyn_cast<EnumInst>(str)) {
        assert(ei->getNumOperands() == 1 && "expect non-null optional");
        str = ei->getOperand();
        continue;
      }

      if (auto *ubc = dyn_cast<UncheckedBitwiseCastInst>(str)) {
        str = ubc->getOperand();
        continue;
      }

      // Look through the various operands that bit-mangle things into bridged
      // string representations.  This is gross, Swift should have higher level
      // operations for bridge values like this.
      if (auto *bi = dyn_cast<BuiltinInst>(str)) {
        switch (bi->getBuiltinInfo().ID) {
        case BuiltinValueKind::And:
        case BuiltinValueKind::Or:
        case BuiltinValueKind::ZExtOrBitCast:
        case BuiltinValueKind::PtrToInt:
          str = bi->getOperand(0);
          continue;
        default: break;
        }
      }

      // It is possible that we have a variable string, we want to reject it
      // as a non-constant value.
      return nullptr;
    }
  }

  // Handle cases that create a literal array.
  if (auto *si = dyn_cast<StructInst>(v)) {
    SmallVector<SILValue, 8> elements;
    Type elementType;
    if (decodeArrayElements(v, elements, elementType)) {
      for (auto elt : elements)
        if (!getAttrOperand(elt))
          return nullptr;
      return si;
    }
  }

  // Simplify scalar operands in general.
  v = getScalarOperand(v);
  if (!v) return nullptr;

  // If we have an acceptable values for an attribute, return it.
  if (auto *fli = dyn_cast<FloatLiteralInst>(v))
    return fli;
  if (auto *ili = dyn_cast<IntegerLiteralInst>(v))
    return ili->getValue().getBitWidth() <= 64 ? ili : nullptr;
  if (auto *sli = dyn_cast<StringLiteralInst>(v))
    return sli->getEncoding() == StringLiteralInst::Encoding::UTF8
           ? sli : nullptr;
  if (auto *mti = dyn_cast<MetatypeInst>(v)) {
    auto ty = mti->getType().castTo<AnyMetatypeType>()->getInstanceType();
    if (convertSwiftTypeToTF(ty) != 0) return mti;
  }

  return nullptr;
}


/// Analyze the specified SIL instruction and return a SILTensorOpInfo result if
/// the instruction is a valid tensor operation.  This is the way that
/// SILTensorOpInfo's are created.
Optional<SILTensorOpInfo>
SILTensorOpInfo::decode(SILInstruction *inst) {
  // Tuple extracts of tensor ops are considered to be themselves Tensor
  // operations, since they are part of the core representation of nodes that
  // produce multiple results.
  if (auto *ti = dyn_cast<TupleExtractInst>(inst))
    if (auto *ai = dyn_cast<BuiltinInst>(ti->getOperand()))
      inst = ai;

  // Tensor operations are builtin instructions and apply instructions.
  if (auto *builtin = dyn_cast<BuiltinInst>(inst)) {
    SILTensorOpInfo toiInfo(builtin);
    if (toiInfo.decodeBuiltin())
      return toiInfo;
  }
  return None;
}

typedef std::pair<StringRef, OperandClass> AttributeEntry;

/// Given a builtin name that refer to a tensorflow op function, this returns
/// the op name and operand clases and returns an empty string.  If the string
/// provided is invalid, this returns an error message to present.
static std::string
decodeTensorOpName(StringRef name, StringRef &opName,
                   SmallVectorImpl<AttributeEntry> &operandClasses){
  // Decode the base name for the op.
  auto pos = name.find(",");
  opName = name.substr(0, pos);
  if (pos == StringRef::npos) return "";
  name = name.substr(pos);

  // Parse out operand information.
  while (!name.empty()) {
    assert(name[0] == ',');
    name = name.drop_front(1);

    pos = name.find(",");
    if (pos == StringRef::npos) pos = name.size();

    // Parse out the attribute name.  If it contains a $, then parse out the
    // OperandClass as well.
    auto attrName = name.substr(0, pos);

    // Figure out what the suffix is (if any) and reject invalid suffixes if
    // present.
    auto dollarLoc = attrName.find('$');

    auto opClass = OperandClass::Normal;
    if (dollarLoc != StringRef::npos) {
      auto suffix = attrName.drop_front(dollarLoc+1);
      if (auto res = SILTensorOpInfo::getOperandClass(suffix))
        opClass = res.getValue();
      else {
        return "invalid attribute modifier '" + attrName.str() + "'";
      }
    }

    // Slice the suffix off the attribute name and add the decoded version.
    operandClasses.push_back({
      attrName.substr(0, dollarLoc), opClass
    });
    name = name.substr(pos);
  }

  return "";
}

/// The vast majority of interesting tensor operations are builtin instructions,
/// which come from the user-exposed #tfop() syntax.
bool SILTensorOpInfo::decodeBuiltin() {
  builtinName = inst->getName().str();

  // If the builtin doesn't start with our magic prefix, then it isn't an op.
  if (!builtinName.startswith("__tfop_"))
    return false;

  // This helper emits a diagnostic if the #tfop descriptor is malformed in a
  // way that prevents it from ever working.  Errors that are a result of a
  // client's misuse of the op is checked by checkAttributeConstants, because
  // the location information is far more important to get right there.
  auto diagInvalid = [&](std::string problem) {
    diagnose(inst->getModule().getASTContext(), inst->getLoc().getSourceLoc(),
             diag::tfop_invalid_tfop, problem);
  };

  // Ok, it is, decode and validate it.
  auto errStr = decodeTensorOpName(builtinName.substr(strlen("__tfop_")),
                                   opName, operandClasses);
  if (!errStr.empty()) {
    diagInvalid(errStr);
    return false;
  }

  // Validate that this instruction is ok.
  if (inst->getNumOperands() != operandClasses.size()) {
    diagInvalid("op has " + llvm::utostr(operandClasses.size()) +
                " operand classes, but " + llvm::utostr(inst->getNumOperands())+
                " inputs and attributes");
    return false;
  }

  // Check all the input operands to this builtin to make sure any scalar values
  // can be resolved.  We don't have to check the actual values passed into
  // attributes here - they get checked in a separate pass so we can diagnose
  // errors better.
  for (unsigned i = 0, e = inst->getNumOperands(); i != e; ++i) {
    auto op = inst->getOperand(i);

    if (!isInput(i))
      continue;

    // Input operands can be either a TensorHandle or a scalar.
    if (isTensorHandle(op->getType()))
      continue;

    // If it isn't a TensorHandle, it is a scalar.
    op = getScalarOperand(op);

    auto scalarType = op->getType().getSwiftRValueType();
    if (convertSwiftTypeToTF(scalarType) == 0) {
      diagInvalid("operand has unrecognized type '" +
                  scalarType->getString() + "'");
      return SILValue();
    }
  }

  return true;
}

/// addTensorOperand - Decode the specified array value (which should be an
/// array of constant integer or fp values) and add it as a value$tensor operand
/// to the specified op that is being built up.  This returns false if the
/// operand is not an array of constant values.
static bool expandArrayAttribute(SILValue arrayVal, StringRef attrName,
                                 OperandClass attrKind,
                                 std::string &name,
                                 SmallVectorImpl<SILValue> &operands,
                                 SILInstruction *forInst) {
  // Otherwise, this is an array attribute, so expand it out.
  SmallVector<SILValue, 8> elements;
  Type elementType;
  bool isArray = decodeArrayElements(arrayVal, elements, elementType);
  if (!isArray) return false;

  // Verify that we have all constants.
  for (auto &elt : elements) {
    elt = SILTensorOpInfo::getAttrOperand(elt);
    if (!elt) return false;
  }

  SILBuilder B(forInst);

  // Add the first operand, which is the metatype for the element.  If it was
  // a 'Normal' operand, change it to an Array so we can distinguish it in the
  // case of an empty array.
  if (attrKind == OperandClass::Normal)
    attrKind = OperandClass::Array;
  name += ","+attrName.str();
  name += SILTensorOpInfo::getOperandClassSuffix(attrKind);

  auto metatypeType =
    MetatypeType::get(elementType, MetatypeRepresentation::Thin)
      ->getCanonicalType();
  operands.push_back(B.createMetatype(forInst->getLoc(),
                              SILType::getPrimitiveObjectType(metatypeType)));

  // Add all of the operands as explicit values.  If the instructions came
  // from an out of line array initializer, make sure to clone them over to
  // our function.
  for (auto eltVal : elements) {
    auto elt = cast<SingleValueInstruction>(eltVal);
    if (elt->getFunction() != forInst->getFunction()) {
      // Make a copy of the instruction.  We can't even use the normal cloning
      // facilities here, because they don't support cloning across functions.
      if (auto *eltInt = dyn_cast<IntegerLiteralInst>(elt))
        elt = B.createIntegerLiteral(eltInt->getLoc(), eltInt->getType(),
                                     eltInt->getValue());
      else if (auto *eltFP = dyn_cast<FloatLiteralInst>(elt))
        elt = B.createFloatLiteral(eltFP->getLoc(), eltFP->getType(),
                                   eltFP->getValue());
      else
        llvm_unreachable("Unknown instruction to initialize array");
      elt->setDebugLocation(B.getSILDebugLocation(forInst->getLoc()));
    }

    operands.push_back(elt);
    name += ",";
    name += SILTensorOpInfo::getOperandClassSuffix(OperandClass::ArrayElement);
  }

  return true;
}

/// If all the operands to a call to __tf_tensor_from_scalars are constants, we
/// can promote this to a 'Const' node with an attached TF_Tensor attribute.
///
/// It takes a 1D array of scalars, a shape as a 1D array of integers, and a
/// metatype that corresponds to the Scalar type.  This has been carefully set
/// up to align with what the Const op wants to see.
///
SILInstruction *SILTensorOpInfo::decodeTensorFromScalars(ApplyInst *inst) {
  assert(inst->getNumOperands() == 3 && isTensorHandle(inst->getType()) &&
         "Unexpected type signature for __tf_tensor_from_scalars");

  // If we can't analyze the operands as arrays of constants, give up.
  auto scalars = getAttrOperand(inst->getOperand(1));
  auto shape = getAttrOperand(inst->getOperand(2));
  if (!scalars || !shape)
    return inst;

  // We transform this into a __tfop_Const instruction, where the values are
  // part of the 'value' tensor attribute and the shape is specified as a shape
  // attribute.
  SmallVector<SILValue, 8> operands;
  std::string name = "__tfop_Const";

  // Try to expand the array and the shape into their scalars.
  if (!expandArrayAttribute(scalars, "value", OperandClass::Tensor,
                            name, operands, inst))
    return inst;

  unsigned numElements = operands.size()-1;

  if (!expandArrayAttribute(shape, "value", OperandClass::Shape,
                            name, operands, inst))
    return inst;

  // Verify we have the right number of scalars.  If not, emit an error and
  // leave the broken code without promoting it to an op.
  uint64_t scalarCount = 1;
  std::string errorInfo;
  for (auto elt : ArrayRef<SILValue>(operands).drop_front(numElements+2)) {
    auto *eltCst = cast<IntegerLiteralInst>(elt);
    scalarCount *= eltCst->getValue().getLimitedValue();
  }
  if (scalarCount != numElements && errorInfo.empty()) {
    errorInfo = "tensor literal should have " + llvm::utostr(scalarCount) +
          " scalars for this shape, but has " + llvm::utostr(numElements);
  }

  if (!errorInfo.empty()) {
    auto loc = getUserSourceLocation(inst);
    diagnose(inst->getType().getSwiftRValueType()->getASTContext(),
             loc.getSourceLoc(), diag::tf_op_misuse, errorInfo)
      .highlight(loc.getSourceRange());
    return inst;
  }

  // This takes a Tensor and a Shape operand, but needs a DType added.  The
  // dtype is the type of the Tensor elements, which we conveniently already
  // have available as the first operand.
  operands.push_back(operands[0]);
  name += ",dtype";

  SILBuilder B(inst);

  // Finally build a new builtin instruction with the simplified operands.
  auto newInst =
    B.createBuiltin(inst->getLoc(),
                    B.getASTContext().getIdentifier(name),
                    inst->getType(), /*no substitions*/{},
                    operands);
  newInst->setDebugLocation(inst->getDebugLocation());
  inst->replaceAllUsesPairwiseWith(newInst);
  inst->eraseFromParent();
  return newInst;
}

/// If all the operands to a call to __tf_tensor_from_scalars_1d are constants,
/// we can promote this to a 'Const' node with an attached TF_Tensor attribute.
/// This is a specialized form of __tf_tensor_from_scalars, because the later is
/// defined in terms of a shape of "[scalars.count]" but the performance
/// optimizer is not reliably constant propagating this.  When we have a
/// reliable deabstraction pass we can re-evaluate this and hopefully eliminate
/// it in favor of library code in the TensorFlow module.
///
SILInstruction *SILTensorOpInfo::decodeTensorFromScalars1D(ApplyInst *inst) {
  assert(inst->getNumOperands() == 2 && isTensorHandle(inst->getType()) &&
         "Unexpected type signature for __tf_tensor_from_scalars_1d");

  // If we can't analyze the operands as arrays of constants, give up.
  auto scalars = getAttrOperand(inst->getOperand(1));
  if (!scalars)
    return inst;

  // We transform this into a __tfop_Const instruction, where the values are
  // part of the 'value' tensor attribute and the shape is hard coded.
  SmallVector<SILValue, 8> operands;
  std::string name = "__tfop_Const";

  // Try to expand the array into its scalars.
  if (!expandArrayAttribute(scalars, "value", OperandClass::Tensor,
                            name, operands, inst))
    return inst;

  SILBuilder B(inst);

  // This takes a Tensor operand, but needs a Shape and a DType added.  At
  // this point, the operands list will have a metatype for the tensor as
  // the first operand then all the elements.
  uint64_t scalarCount = operands.size()-1;

  // The shape needs a metatype to be well formed, but nothing actually
  // cares what it is.  Just re-push the metatype for the tensor elements,
  // even though it might be floating point or something else weird.
  operands.push_back(operands[0]);
  name += ",shape";
  name += getOperandClassSuffix(OperandClass::Shape);

  // The shape of a 1d tensor is just the count of elements.
  auto &ctx = inst->getFunction()->getASTContext();
  auto scalarCountVal =
    B.createIntegerLiteral(inst->getLoc(),
                           SILType::getBuiltinIntegerType(64, ctx),
                           scalarCount);
  operands.push_back(scalarCountVal);
  name += ",";
  name += getOperandClassSuffix(OperandClass::ArrayElement);

  // The  dtype is the type of the Tensor elements, which we conveniently
  // already have available as the first operand.
  operands.push_back(operands[0]);
  name += ",dtype";

  // Finally build a new builtin instruction with the simplified operands.
  auto newInst =
    B.createBuiltin(inst->getLoc(),
                    B.getASTContext().getIdentifier(name),
                    inst->getType(), /*no substitions*/{},
                    operands);
  newInst->setDebugLocation(inst->getDebugLocation());
  inst->replaceAllUsesPairwiseWith(newInst);
  inst->eraseFromParent();
  return newInst;
}

/// If the specified call is to a function that we can promote to an op,
/// rewrite the instruction and return a new one that does so.  Otherwise,
/// return the same instruction.
SILInstruction *SILTensorOpInfo::decodeApply(ApplyInst *apply, StringRef name) {
  if (name == "__tf_tensor_from_scalars")
    return decodeTensorFromScalars(apply);
  if (name == "__tf_tensor_from_scalars_1d")
    return decodeTensorFromScalars1D(apply);

  return apply;
}



/// Return the string suffix for the specified attribute modifier.
const char *SILTensorOpInfo::
getOperandClassSuffix(OperandClass opClass) {
  switch (opClass) {
  case OperandClass::Input: return "$in";
  case OperandClass::Normal: return "";
  case OperandClass::DType: return "$dtype";
  case OperandClass::Tensor: return "$tensor";
  case OperandClass::Shape: return "$shape";
  case OperandClass::Array: return "$array";
  case OperandClass::ArrayElement: return "$elt";
  }
}

/// Return the operand class of the specified string form like "tensor"
llvm::Optional<OperandClass>
SILTensorOpInfo::getOperandClass(StringRef suffix) {
  return llvm::StringSwitch<llvm::Optional<OperandClass>>(suffix)
                  .Case("in", OperandClass::Input)
                  .Case("", OperandClass::Normal)
                  .Case("tensor", OperandClass::Tensor)
                  .Case("shape", OperandClass::Shape)
                  .Case("dtype", OperandClass::DType)
                  .Case("array", OperandClass::Array)
                  .Case("elt", OperandClass::ArrayElement)
                  .Default(None);
}


/// Verify that any attribute operands are passed acceptable constants,
/// returning a non-empty error string to emit if that is not the case.
std::string SILTensorOpInfo::checkAttributeConstants() const {
  // Attribute values require constant values.  If we don't have one then this
  // op is invalid and must be rejected.
  for (unsigned i = 0, e = operandClasses.size(); i != e; ++i) {
    auto attr = operandClasses[i];
    if (attr.second == OperandClass::Input)
      continue;

    auto operand = getAttrOperand(i);
    if (!operand)
      return "attribute '" + attr.first.str() +"' requires a constant argument";

    // Check additional requirements imposed by attribute modifiers.
    switch (attr.second) {
    case OperandClass::Input:
      llvm_unreachable("handled above");
    case OperandClass::Normal:  // No modifier.
      break;
    case OperandClass::DType:   // This integer value is a dtype.
      if (!isa<IntegerLiteralInst>(operand))
        return "attribute '" + attr.first.str()+"' requires a constant integer";
      break;
    case OperandClass::Shape:
    case OperandClass::Array:
      // Decoded shape values are represented by a metatype, and are optionally
      // followed by array element values.
      if (isa<MetatypeInst>(operand))
        break;
      return "attribute '" + attr.first.str() +
        "' requires a constant integer or floating point constant";

    case OperandClass::ArrayElement:
      // Integer and float elements work.
      if (isa<IntegerLiteralInst>(operand) ||
          isa<FloatLiteralInst>(operand))
        break;
      return "attribute '" + attr.first.str() +
        "' requires a constant integer or floating point constant";

    case OperandClass::Tensor:
      // If this an integer or float, it should be turned into a TF_Tensor.
      if (isa<IntegerLiteralInst>(operand) ||
          isa<FloatLiteralInst>(operand))
        break;

      // Decoded tensor value as represented by a metatype, and are optionally
      // followed by array element values.
      if (isa<MetatypeInst>(operand))
        break;

      // Otherwise, if it is an array, it should be decodable and should be
      // followed by a shape.
      if (isa<StructInst>(operand)) {
        Type scalarsElementType;
        SmallVector<SILValue, 16> scalars;
        if (!decodeArrayElements(operand, scalars, scalarsElementType)) {
          return "attribute '" + attr.first.str() +
                 "' requires an array of constant values";
        }

        // Check that all the elements are constants.
        for (auto elt : scalars) {
          if (!getAttrOperand(elt))
            return "attribute '" + attr.first.str() +
                   "' requires an array of constant values";
        }

        // The next operand must be a shape.
        if (i+1 >= operandClasses.size() ||
            attr.first != operandClasses[i].first ||
            operandClasses[i+1].second != OperandClass::Shape) {
          // If we have a call to a well-known C function that will be promoted
          // to a tensor op, then we don't need a shape, it will be synthesized
          // later.
          if (isa<ApplyInst>(inst))
            break;

          return "tensor array attribute '" + attr.first.str() +
                 "' must be followed by a shape";
        }

        auto shapeOperand = getAttrOperand(++i);
        if (!shapeOperand || !isa<StructInst>(shapeOperand))
          return "attribute '" + attr.first.str() + "' has invalid shape";

        Type shapeElementType;
        SmallVector<SILValue, 4> shape;
        if (!decodeArrayElements(shapeOperand, shape, shapeElementType))
          return "attribute '" + attr.first.str() + "' has non-constant shape";

        // Verify we have the right number of scalars.
        uint64_t scalarCount = 1;
        for (auto elt : shape) {
          auto *eltCst =
            dyn_cast_or_null<IntegerLiteralInst>(getAttrOperand(elt));
          if (!eltCst)
            return "attribute '" + attr.first.str() + "' has non-constant shape";

          scalarCount *= eltCst->getValue().getLimitedValue();
        }
        if (scalarCount != scalars.size())
          return "tensor literal should have " + llvm::utostr(scalarCount) +
             " scalars for this shape, but has " + llvm::utostr(scalars.size());

        // If everything is ok, then we're good to go.
        break;
      }

      return "attribute '" + attr.first.str() +
        "' requires a constant integer or floating point constant";
    }
  }

  // Otherwise everything is ok.
  return "";
}

/// Replace any indirect memory operands with direct references to the
/// scalars they reference.  This potentially replaces the builtin
/// instruction, so it returns the right one to use.
// TODO(clattner): Move this into deabstraction when it exists.
SILInstruction *SILTensorOpInfo::canonicalizeOperands() {
  SmallVector<SILValue, 8> operands;

  std::string name = "__tfop_" + opName.str();
  SILBuilder B(inst);

  for (unsigned i = 0, e = inst->getNumOperands(); i != e; ++i) {
    auto operand = inst->getOperand(i);
    auto opInfo = operandClasses[i];
    std::string opName =
      "," + opInfo.first.str() + getOperandClassSuffix(opInfo.second);

    // Handle inputs.
    if (operandClasses[i].second == OperandClass::Input) {
      if (!isTensorHandle(operand->getType()))
        operand = getScalarOperand(operand);

      operands.push_back(operand);
      name += opName;
      continue;
    }

    // Handle attributes.
    auto attrOperand = getAttrOperand(operand);

    // If this is a normal operand, just add it.
    auto *si = dyn_cast<StructInst>(attrOperand);
    if (!si) {
      // Otherwise, this is a normal operand.
      operands.push_back(attrOperand);
      name += opName;
      continue;
    }

    // If this is an array, then we need to expand it out into its constituent
    // elements.
    bool isArray = expandArrayAttribute(attrOperand, opInfo.first,
                                        opInfo.second, name, operands, inst);
    assert(isArray && "array should be validated in earlier pass");

    // Emit a release of the array, since we've dropped the consuming use of it.
    B.emitDestroyValueOperation(inst->getLoc(), attrOperand);
  }

  // Determine whether canonicalization changed anything.
  bool changed = name != builtinName ||
                 operands.size() != inst->getNumOperands();
  for (unsigned i = 0, e = operands.size(); !changed && i != e; ++i)
    changed |= operands[i] != inst->getOperand(i);

  // If everything is already copasetic, just return our existing instruction.
  if (!changed)
    return inst;

  // Otherwise, rebuild a new builtin instruction with the simplified operands.
  auto *newInst =
    B.createBuiltin(inst->getLoc(),
                    B.getASTContext().getIdentifier(name),
                    inst->getType(), /*no substitions*/{}, operands);
  newInst->setDebugLocation(inst->getDebugLocation());

  inst->replaceAllUsesPairwiseWith(newInst);
  inst->eraseFromParent();

  // Now that we have a new instruction, reparse it to make sure that our
  // internal state is all up to date, and that we built it correctly.
  auto newResult = decode(newInst);
  assert(newResult.hasValue() && "Misformed builtin when canonicalizing");
  *this = newResult.getValue();
  return newInst;
}



/// The SIL location for operations we process are usually deep in the bowels
/// of the tensor library code, which are all implementation details to the
/// user.  As such, walk the inlining location of the specified node to return
/// the first location *outside* of the tensor implementation goop.
SILDebugLocation tf::skipInternalLocations(SILDebugLocation loc) {
  auto ds = loc.getScope();

  if (!ds) return loc;

  // If this location hasn't been inlined at all, just keep it unmodified.
  if (!ds->InlinedCallSite && loc.getLocation().getSourceLoc().isValid())
    return loc;

  // Zip through inlined call site information that came from the
  // implementation guts of the tensor library.  We want to report the
  // message inside the user's code, not in the guts we inlined through.
  for (; auto ics = ds->InlinedCallSite; ds = ics) {
    // If we found a valid inlined-into location, then we are good.
    if (ds->Loc.getSourceLoc().isValid())
      return SILDebugLocation(ds->Loc, ds);
    if (SILFunction *F = ds->getInlinedFunction()) {
      if (F->getLocation().getSourceLoc().isValid())
        break;
    }
  }

  if (!ds->Loc.isNull())
    return SILDebugLocation(ds->Loc, ds);

  return loc;
}

SILLocation tf::getUserSourceLocation(SILValue value) {
  if (auto *inst = dyn_cast<SILInstruction>((SILNode*)value))
    return getUserSourceLocation(inst);
  return getUserSourceLocation(value.getDebugLocation());
}

/// Get the user's source location for the specified instruction.  Because it
/// is an instruction, we can apply various heuristics to improve the
/// precision of the returned location information.
SILLocation tf::getUserSourceLocation(SILInstruction *inst) {
  // If we have a struct extract from a type like Int, Float, or Tensor of an
  // internal type like Builtin.i64 or TensorHandle, look through it to the
  // higher level type, which will have better source location information.
  //
  // The struct-extract came from the implementation of some operator in the
  // standard library like "+", and we want the source of the parameter.
  if (auto *sei = dyn_cast<StructExtractInst>(inst)) {
    auto outerType = sei->getType().getSwiftRValueType();
    if (outerType->is<BuiltinType>() || isTensorHandle(outerType)) {
      return getUserSourceLocation(sei->getOperand());
    }
  }

  return getUserSourceLocation(inst->getDebugLocation());
}
