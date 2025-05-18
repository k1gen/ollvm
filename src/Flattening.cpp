#include "llvm/IR/Constants.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"
#include "include/Flattening.h"
#include "include/LegacyLowerSwitch.h"
#include "include/Utils.h"
#include "include/CryptoUtils.h"
#include "llvm/ADT/Statistic.h"
#include "include/ObfuscationOptions.h"

#define DEBUG_TYPE "flattening"
using namespace llvm;

STATISTIC(Flattened, "Functions flattened");

namespace {
struct Flattening : public FunctionPass {
  static char ID;
  unsigned pointerSize;
  ObfuscationOptions *ArgsOptions;
  CryptoUtils RandomEngine;

  Flattening(unsigned pointerSize, ObfuscationOptions *argsOptions)
      : FunctionPass(ID), pointerSize(pointerSize), ArgsOptions(argsOptions) {}

  bool runOnFunction(Function &F) override;
  bool flatten(Function *f, const ObfOpt &opt);
};
} // namespace

char Flattening::ID = 0;
static RegisterPass<Flattening> X("flattening", "Control-flow flattening");

FunctionPass *llvm::createFlatteningPass(unsigned pointerSize,
                                         ObfuscationOptions *argsOptions) {
  return new Flattening(pointerSize, argsOptions);
}

bool Flattening::runOnFunction(Function &F) {
  auto opt = ArgsOptions->toObfuscate(ArgsOptions->flaOpt(), &F);
  if (!opt.isEnabled())
    return false;
  if (flatten(&F, opt)) {
    ++Flattened;
    return true;
  }
  return false;
}

bool Flattening::flatten(Function *f, const ObfOpt &opt) {
  SmallVector<BasicBlock *, 16> origBB;
  for (auto &BB : *f) {
    origBB.push_back(&BB);
    if (isa<InvokeInst>(BB.getTerminator()))
      return false;
  }
  if (origBB.size() <= 1)
    return false;

  LLVMContext &Ctx = f->getContext();
  unsigned BW = (pointerSize == 8 ? 64 : 32);
  IntegerType *intType = IntegerType::get(Ctx, BW);

  // Generate scramble key
  std::array<unsigned char, 16> key;
  RandomEngine.get_bytes(reinterpret_cast<char *>(key.data()), key.size());

  // Lower switches
  std::unique_ptr<FunctionPass> lower(createLegacyLowerSwitchPass());
  lower->runOnFunction(*f);

  // Drop entry block from origBB
  origBB.erase(origBB.begin());
  BasicBlock *entry = &f->getEntryBlock();

  // IRBuilder anchored at entry
  IRBuilder<> Builder(entry);

  // Possibly split entry
  if (auto *br0 = dyn_cast<BranchInst>(entry->getTerminator())) {
    if (br0->isConditional() || br0->getNumSuccessors() > 1) {
      auto it = entry->end();
      --it;
      if (entry->size() > 1)
        --it;
      BasicBlock *newBB = entry->splitBasicBlock(it, "first");
      origBB.insert(origBB.begin(), newBB);
      entry = newBB;
      Builder.SetInsertPoint(entry);
    }
  }

  // Remove old terminator
  if (auto *oldT = entry->getTerminator())
    oldT->eraseFromParent();

  // Allocate switch variable
  AllocaInst *switchVar = Builder.CreateAlloca(intType, nullptr, "switchVar");

  // Initialize switchVar
  uint64_t initRaw = (BW == 64)
                         ? RandomEngine.scramble64(
                               0, reinterpret_cast<const char *>(key.data()))
                         : RandomEngine.scramble32(
                               0, reinterpret_cast<const char *>(key.data()));
  APInt initAP(BW, initRaw);
  APInt clampedInit = initAP.zextOrTrunc(BW);
  Value *initVal = ConstantInt::get(intType, clampedInit);
  Builder.CreateStore(initVal, switchVar);

  // Create loop entry/end
  BasicBlock *loopEntry = BasicBlock::Create(Ctx, "loopEntry", f, entry);
  BasicBlock *loopEnd = BasicBlock::Create(Ctx, "loopEnd", f, loopEntry);
  Builder.CreateBr(loopEntry);

  // Default case block
  BasicBlock *defaultBB = BasicBlock::Create(Ctx, "switchDefault", f, loopEnd);
  IRBuilder<> DefB(defaultBB);
  DefB.CreateBr(loopEnd);

  // Build switch in loopEntry
  Builder.SetInsertPoint(loopEntry);
  LoadInst *load = Builder.CreateLoad(intType, switchVar, "switchVar");
  SwitchInst *sw = Builder.CreateSwitch(load, defaultBB, origBB.size());

  // loopEnd back-edge
  Builder.SetInsertPoint(loopEnd);
  Builder.CreateBr(loopEntry);

  // Add cases
  for (BasicBlock *BB : origBB) {
    uint64_t rawVal =
        (BW == 64)
            ? RandomEngine.scramble64(
                  sw->getNumCases(), reinterpret_cast<const char *>(key.data()))
            : RandomEngine.scramble32(
                  sw->getNumCases(),
                  reinterpret_cast<const char *>(key.data()));
    APInt caseAP(BW, rawVal);
    APInt clampedCase = caseAP.zextOrTrunc(BW);
    ConstantInt *CI = cast<ConstantInt>(ConstantInt::get(intType, clampedCase));
    BB->moveBefore(loopEnd);
    sw->addCase(CI, BB);
  }

  // Rewrite original terminators
  for (BasicBlock *BB : origBB) {
    Instruction *term = BB->getTerminator();
    if (!term)
      continue;
    unsigned succs = term->getNumSuccessors();
    BranchInst *br = dyn_cast<BranchInst>(term);
    term->eraseFromParent();
    Builder.SetInsertPoint(BB);

    if (succs == 1) {
      uint64_t rv = (BW == 64)
                        ? RandomEngine.scramble64(
                              sw->getNumCases(),
                              reinterpret_cast<const char *>(key.data()))
                        : RandomEngine.scramble32(
                              sw->getNumCases(),
                              reinterpret_cast<const char *>(key.data()));
      APInt ap(BW, rv);
      APInt cp = ap.zextOrTrunc(BW);
      Value *nv = Builder.CreateSub(initVal, ConstantInt::get(intType, cp));
      Builder.CreateStore(nv, switchVar);
      Builder.CreateBr(loopEnd);

    } else if (succs == 2 && br) {
      uint64_t tV = (BW == 64)
                        ? RandomEngine.scramble64(
                              sw->getNumCases(),
                              reinterpret_cast<const char *>(key.data()))
                        : RandomEngine.scramble32(
                              sw->getNumCases(),
                              reinterpret_cast<const char *>(key.data()));
      uint64_t fV = (BW == 64)
                        ? RandomEngine.scramble64(
                              sw->getNumCases(),
                              reinterpret_cast<const char *>(key.data()))
                        : RandomEngine.scramble32(
                              sw->getNumCases(),
                              reinterpret_cast<const char *>(key.data()));
      APInt tap(BW, tV);
      APInt fap(BW, fV);
      Value *vt = Builder.CreateSub(initVal, ConstantInt::get(intType, tap));
      Value *vf = Builder.CreateSub(initVal, ConstantInt::get(intType, fap));
      Value *sel = Builder.CreateSelect(br->getCondition(), vt, vf);
      Builder.CreateStore(sel, switchVar);
      Builder.CreateBr(loopEnd);
    }
  }

  return true;
}
