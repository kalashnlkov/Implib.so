
  .globl $sym
  .p2align 4
  .type $sym, %function
#ifndef IMPLIB_EXPORT_SHIMS
  .hidden $sym
#endif
$sym:
  .cfi_startproc
  .cfi_def_cfa_offset 8  // Return address
  // Intel opt. manual says to
  // "make the fall-through code following a conditional branch be the likely target for a branch with a forward target"
  // to hint static predictor.
  cmpq $$0, _${lib_suffix}_tramp_table+$offset(%rip)
  je 2f
1:
  jmp *_${lib_suffix}_tramp_table+$offset(%rip)
2:
  pushq $$$number
  .cfi_adjust_cfa_offset 8
  call _${lib_suffix}_save_regs_and_resolve
  addq $$8, %rsp
  .cfi_adjust_cfa_offset -8
  jmp 1b
  .cfi_endproc

